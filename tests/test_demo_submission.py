"""Submission boundaries; all identities and database calls are isolated fakes."""
import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from app.routes import campaigns


class SubmissionTests(unittest.IsolatedAsyncioTestCase):
    async def test_finalize_cannot_impersonate_other_creator(self):
        with patch.object(campaigns.db_mod, "finalize_campaign", new=AsyncMock()) as save:
            with self.assertRaises(HTTPException) as caught:
                await campaigns.finalize_campaign({"creator_id": "other"}, SimpleNamespace(id="me"))
        self.assertEqual(caught.exception.status_code, 403)
        save.assert_not_awaited()

    async def test_finalize_uses_authenticated_identity(self):
        with patch.object(campaigns.db_mod, "finalize_campaign", new=AsyncMock(return_value={"campaign_id": 99})) as save:
            await campaigns.finalize_campaign({"title": "Isolated QA"}, SimpleNamespace(id="me"))
        self.assertEqual(save.call_args.args[0]["creator_id"], "me")

    async def test_owner_cannot_directly_publish_draft(self):
        campaign = SimpleNamespace(creator_id="me", status="draft")
        db = SimpleNamespace(execute=AsyncMock(return_value=SimpleNamespace(
            scalar_one_or_none=lambda: campaign)), flush=AsyncMock())
        with self.assertRaises(HTTPException) as caught:
            await campaigns.publish_campaign("99", SimpleNamespace(id="me"), db)
        self.assertEqual(caught.exception.status_code, 409)
        self.assertEqual(campaign.status, "draft")
        db.flush.assert_not_awaited()

    async def test_other_creator_cannot_publish(self):
        db = SimpleNamespace(execute=AsyncMock(return_value=SimpleNamespace(
            scalar_one_or_none=lambda: SimpleNamespace(creator_id="other", status="draft"))))
        with self.assertRaises(HTTPException) as caught:
            await campaigns.publish_campaign("99", SimpleNamespace(id="me"), db)
        self.assertEqual(caught.exception.status_code, 403)
