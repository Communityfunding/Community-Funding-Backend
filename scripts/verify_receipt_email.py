"""Exercise real Resend using its official sink and an isolated DB adapter.

No Railway donation/outbox changes, real user recipient or payment.
Credentials are supplied in environment; never printed or saved.
"""
import asyncio
import json
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from app.donation_receipts import deliver_receipt


class Result:
    def mappings(self):
        return self
    def first(self):
        return {"id":"qa-receipt-probe-20261006","provider_id":None,
                "donor_email":"delivered+cf-receipt-qa@resend.dev",
                "amount":"1.00","title":"TEST — isolated receipt probe"}


class IsolatedDatabase:
    async def execute(self,query,params=None):
        return Result()
    async def commit(self):
        pass


async def main():
    try:
        status=await deliver_receipt(IsolatedDatabase(),"qa-receipt-probe-20261006")
        print(json.dumps({"receipt_email_status":status,"recipient":"official Resend test sink",
                          "railway_database_modified":False,"real_payment":False}))
    except Exception:
        print(json.dumps({"receipt_email_status":"not_verified","credentials_printed":False}))
        raise SystemExit(1) from None


if __name__=="__main__":
    asyncio.run(main())
