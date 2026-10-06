"""No network, credentials, real payments or live database changes."""
import unittest
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from pydantic import ValidationError
from app.routes import donations_v2 as routes


class Result:
    def __init__(self, value):
        self.value = value

    def mappings(self):
        return self

    def first(self):
        return self.value

    def scalar_one(self):
        return self.value


class Database:
    def __init__(self, values):
        self.values = iter(values)
        self.queries = []
        self.commit = AsyncMock()
        self.rollback = AsyncMock()

    async def execute(self, query, params=None):
        self.queries.append((str(query), params))
        return Result(next(self.values))


CAMPAIGN = {"campaign_id": 2, "title": "Isolated QA", "status": "active",
            "url": "qa", "creator_id": "creator"}


class DonationTests(unittest.IsolatedAsyncioTestCase):
    async def test_guest_checkout_uses_uuid_nullable_donor_and_integer_cents(self):
        db = Database([CAMPAIGN, "qa-uuid", None])
        with patch.object(routes.stripe, "api_key", "sk_test_fake"), \
             patch.object(routes.stripe.checkout.Session, "create",
                          return_value=SimpleNamespace(id="cs_test_qa", url="https://example.test")) as create:
            response = await routes.create_checkout_session(
                routes.CheckoutBody(campaign_id=2, amount="10.25"), db, None)
        sql, params = db.queries[1]
        self.assertIn("(id, campaign_id, donor_id", sql)
        self.assertIn("'PENDING'", sql)
        self.assertIsNone(params["duid"])
        self.assertEqual(params["amt"], Decimal("10.25"))
        self.assertEqual(create.call_args.kwargs["line_items"][0]["price_data"]["unit_amount"], 1025)
        self.assertEqual(response["donation_id"], "qa-uuid")

    async def test_invalid_token_does_not_insert_donation(self):
        db = Database([CAMPAIGN])
        with patch.object(routes.stripe, "api_key", "sk_test_fake"), \
             patch("jwt_utils.DEV_JWT_BYPASS", False), \
             patch("jwt_utils.verify_token", side_effect=ValueError("signature")):
            with self.assertRaises(HTTPException) as caught:
                await routes.create_checkout_session(
                    routes.CheckoutBody(campaign_id=2, amount=10), db, "Bearer forged")
        self.assertEqual(caught.exception.status_code, 401)
        self.assertEqual(len(db.queries), 1)

    async def test_draft_cannot_accept_checkout(self):
        db = Database([{**CAMPAIGN, "status": "draft"}])
        with patch.object(routes.stripe, "api_key", "sk_test_fake"):
            with self.assertRaises(HTTPException) as caught:
                await routes.create_checkout_session(routes.CheckoutBody(campaign_id=2, amount=10), db, None)
        self.assertEqual(caught.exception.status_code, 400)
        self.assertEqual(len(db.queries), 1)

    def test_fractional_cent_and_nonfinite_amount_rejected(self):
        for amount in ("10.001", "NaN", "Infinity", "0", "-1"):
            with self.subTest(amount=amount), self.assertRaises(ValidationError):
                routes.CheckoutBody(campaign_id=2, amount=amount)

    async def webhook(self, db, paid=True):
        event = {"type": "checkout.session.completed", "data": {"object": {
            "id": "cs_test_qa", "payment_intent": "pi_test_qa",
            "payment_status": "paid" if paid else "unpaid"}}}
        request = SimpleNamespace(body=AsyncMock(return_value=b"isolated test"))
        with patch.object(routes, "WEBHOOK_SECRET", "fake-test-secret"), \
             patch.object(routes.stripe.Webhook, "construct_event", return_value=event):
            return await routes.stripe_webhook(request, "fake-signature", db)

    async def test_paid_transition_is_atomic_and_uses_cents(self):
        db = Database([{"donation_id": "qa", "campaign_id": 2, "amount": Decimal("10.25")}, None])
        await self.webhook(db)
        self.assertIn("AND status = 'PENDING'", db.queries[0][0])
        self.assertEqual(db.queries[1][1]["cents"], 1025)
        db.commit.assert_awaited_once()

    async def test_duplicate_does_not_increment_campaign(self):
        db = Database([None])
        response = await self.webhook(db)
        self.assertEqual(response["status"], "already_processed_or_unknown")
        self.assertEqual(len(db.queries), 1)
        db.commit.assert_not_awaited()

    async def test_unpaid_completion_does_not_change_database(self):
        db = Database([])
        response = await self.webhook(db, paid=False)
        self.assertEqual(response["status"], "awaiting_payment")
        self.assertEqual(db.queries, [])
