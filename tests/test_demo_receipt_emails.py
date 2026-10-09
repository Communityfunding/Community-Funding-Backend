import unittest
from contextlib import asynccontextmanager
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from app import donation_receipts as emails


class MailTests(unittest.IsolatedAsyncioTestCase):
    def database(self, row):
        result=SimpleNamespace(mappings=lambda:SimpleNamespace(first=lambda:row))
        return SimpleNamespace(execute=AsyncMock(return_value=result),commit=AsyncMock())

    async def test_already_recorded_email_is_not_sent_again(self):
        db=self.database({"provider_id":"previous-send"})
        with patch.object(emails.httpx,"AsyncClient") as client:
            self.assertEqual(await emails.deliver_receipt(db,"qa"),"already_sent_or_not_needed")
        client.assert_not_called()

    async def test_confirmation_escapes_content_and_uses_stable_idempotency(self):
        db=self.database({"id":"qa","provider_id":None,"donor_email":"delivered@resend.dev","amount":"1.00","title":"<script>QA</script>"})
        client=SimpleNamespace(post=AsyncMock(return_value=SimpleNamespace(status_code=200,json=lambda:{"id":"accepted-id"})))
        @asynccontextmanager
        async def context(*args,**kwargs):
            yield client
        with patch.dict(emails.os.environ,{"RESEND_API_KEY":"fake","RESEND_FROM_EMAIL":"qa@example.com","STRIPE_SECRET_KEY":"sk_test_fake"}), \
             patch.object(emails.httpx,"AsyncClient",context):
            result=await emails.deliver_receipt(db,"qa")
        payload=client.post.call_args.kwargs
        self.assertEqual(payload["headers"]["Idempotency-Key"],"community-fundings-receipt/qa")
        self.assertNotIn("<script>",payload["json"]["html"])
        self.assertIn("SANDBOX TEST",payload["json"]["subject"])
        self.assertEqual(result,"accepted_by_provider")
        db.commit.assert_awaited_once()
