"""Exercise actual Stripe test Checkout with an isolated database adapter.

Creates and immediately expires one test session; no platform campaign is
published, no donation is written to Railway, and no payment is confirmed.
Requires an sk_test_ key in the environment; never prints it or the session URL.
"""
import asyncio
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.routes import donations_v2


class Result:
    def __init__(self, value):
        self.value = value

    def mappings(self):
        return self

    def first(self):
        return self.value

    def scalar_one(self):
        return self.value


class IsolatedDatabase:
    async def execute(self, query, params=None):
        sql = str(query)
        if "SELECT campaign_id" in sql:
            return Result({"campaign_id": 2, "title": "TEST - isolated QA checkout, no real funding",
                           "status": "active", "url": "isolated-qa", "creator_id": None})
        if "INSERT INTO donations" in sql:
            return Result(params["did"])
        return Result(None)

    async def commit(self):
        pass

    async def rollback(self):
        pass


async def main():
    if not os.getenv("STRIPE_SECRET_KEY", "").startswith("sk_test_"):
        raise SystemExit("Refusing: a Stripe test key is required.")
    session_id = None
    try:
        result = await donations_v2.create_checkout_session(
            donations_v2.CheckoutBody(
                campaign_id=2, amount="1.00",
                success_url="https://example.com/isolated-qa-success",
                cancel_url="https://example.com/isolated-qa-cancel"),
            IsolatedDatabase(), None)
        session_id = result["session_id"]
        session = donations_v2.stripe.checkout.Session.retrieve(session_id)
        if session.livemode or session.amount_total != 100:
            raise RuntimeError("Unexpected session mode or amount")
        print(json.dumps({"stripe_test_checkout_created": True, "amount_cents": session.amount_total,
                          "live_mode": session.livemode, "payment_confirmed": False,
                          "railway_database_modified": False}))
    except Exception:
        print(json.dumps({"stripe_test_checkout_created": False,
                          "detail": "Test checkout verification failed; no credentials printed."}))
        raise SystemExit(1) from None
    finally:
        if session_id:
            donations_v2.stripe.checkout.Session.expire(session_id)
            print(json.dumps({"test_session_expired": True}))


if __name__ == "__main__":
    asyncio.run(main())
