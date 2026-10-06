"""Financial views must not trust unsigned identities or public receipt IDs."""
import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock
from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient
from app.database import get_db
from app.routes import ledger_v2, donations_v2


class Result:
    def __init__(self, value):
        self.value = value

    def mappings(self):
        return self

    def first(self):
        return self.value

    def all(self):
        return self.value


def receipt_db():
    row = {"donation_id": "isolated-uuid", "amount": 1, "status": "succeeded",
           "time_created": None, "donor_id": "donor", "creator_id": "creator",
           "stripe_checkout_session_id": "cs_test_private", "donor_name": "QA",
           "donor_email": "private@example.test", "campaign_id": 99, "currency": "usd",
           "platform_fee": 0, "net_amount": 1, "is_anonymous": False,
           "campaign_title": "QA", "campaign_slug": "qa",
           "creator_first_name": "QA", "creator_last_name": "Creator"}
    return SimpleNamespace(execute=AsyncMock(return_value=Result(row)))


class FinancialVisibilityTests(unittest.IsolatedAsyncioTestCase):
    async def test_public_receipt_id_is_not_authorization(self):
        with self.assertRaises(HTTPException) as caught:
            await donations_v2.get_donation("isolated-uuid", receipt_db(), None, None)
        self.assertEqual(caught.exception.status_code, 404)

    async def test_unrelated_user_and_wrong_session_cannot_view_receipt(self):
        with self.assertRaises(HTTPException) as caught:
            await donations_v2.get_donation("isolated-uuid", receipt_db(), "wrong", SimpleNamespace(id="other"))
        self.assertEqual(caught.exception.status_code, 404)

    async def test_guest_with_checkout_return_capability_can_view_receipt(self):
        result = await donations_v2.get_donation("isolated-uuid", receipt_db(), "cs_test_private", None)
        self.assertEqual(result["donation_id"], "isolated-uuid")

    async def test_donor_and_creator_can_view_own_receipt(self):
        for identity in ("donor", "creator"):
            result = await donations_v2.get_donation("isolated-uuid", receipt_db(), None, SimpleNamespace(id=identity))
            self.assertEqual(result["status"], "succeeded")

    async def test_ledger_queries_are_scoped_to_authenticated_identity(self):
        db = SimpleNamespace(execute=AsyncMock(return_value=Result([])))
        result = await ledger_v2.donor_ledger(db, SimpleNamespace(id="verified-user"))
        sql, params = db.execute.call_args.args
        self.assertIn("d.donor_id = :uid", str(sql))
        self.assertIn("LOWER(d.status::TEXT)", str(sql))
        self.assertEqual(params["uid"], "verified-user")
        self.assertEqual(result["count"], 0)

    def test_missing_or_forged_ledger_authentication_fails_before_query(self):
        db = SimpleNamespace(execute=AsyncMock())
        async def fake_db():
            yield db
        app = FastAPI()
        app.include_router(ledger_v2.router)
        app.dependency_overrides[get_db] = fake_db
        with TestClient(app) as client:
            for path in ("/api/ledger-v2/donor", "/api/ledger-v2/creator"):
                self.assertEqual(client.get(path).status_code, 401)
                self.assertEqual(client.get(path, headers={"Authorization": "Bearer forged"}).status_code, 401)
        db.execute.assert_not_awaited()
