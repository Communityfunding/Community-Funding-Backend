"""Canonical schema preview contracts; no live database changes."""
import unittest
from contextlib import asynccontextmanager
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

from app.routes import campaign_page


class PreviewTests(unittest.IsolatedAsyncioTestCase):
    async def test_flat_comments_render_readonly_and_keep_saved_status(self):
        connection = SimpleNamespace(
            fetchrow=AsyncMock(return_value={"creator_id": "qa", "name": "QA"}),
            fetchval=AsyncMock(side_effect=[True, 1]),
            fetch=AsyncMock(side_effect=[[], [], [], [{
                "comment_id": "uuid-comment", "comment_text": "Actual content",
                "creator_id": "qa", "time_created": None, "updated_at": None,
            }]]),
        )

        @asynccontextmanager
        async def acquire():
            yield connection

        with patch.object(campaign_page, "_get_campaign_by_url_or_id", new=AsyncMock(
                return_value={"campaign_id": 99, "creator_id": "qa", "status": "pending_review"})), \
             patch.object(campaign_page, "get_pool", new=AsyncMock(return_value=SimpleNamespace(acquire=acquire))), \
             patch.object(campaign_page, "_get_campaign_collaborators", new=AsyncMock(return_value=[])), \
             patch.object(campaign_page, "_get_viewer_collaborator_status", new=AsyncMock(return_value=(False, False))), \
             patch.object(campaign_page, "_get_viewer_saved_status", new=AsyncMock(return_value=True)), \
             patch.object(campaign_page, "_get_friend_ids_for_user", new=AsyncMock(return_value=set())):
            result = await campaign_page.get_campaign_page(
                "qa", page=1, sort_by="newest", current_user=SimpleNamespace(id="qa"))

        self.assertTrue(result["viewer_permissions"]["can_view"])
        self.assertFalse(result["viewer_permissions"]["can_comment"])
        self.assertFalse(result["viewer_permissions"]["supports_comment_threads"])
        self.assertTrue(result["viewer_engagement"]["is_saved"])
        self.assertEqual(result["comments"][0]["comment_text"], "Actual content")
        sql = connection.fetch.call_args.args[0]
        self.assertIn("c.content AS comment_text", sql)
        self.assertIn("NOT COALESCE(c.is_hidden,false)", sql)
        self.assertNotIn("comment_likes", sql)
