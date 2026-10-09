"""Flat comment contracts; isolated data only."""
import unittest
from contextlib import asynccontextmanager
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from fastapi import HTTPException
from app.routes import campaign_page as routes


class FlatCommentTests(unittest.IsolatedAsyncioTestCase):
    def context(self, connection, status="active"):
        @asynccontextmanager
        async def acquire():
            yield connection
        return (
            patch.object(routes, "_get_campaign_by_url_or_id", new=AsyncMock(return_value={
                "campaign_id": 99, "creator_id": "owner", "status": status})),
            patch.object(routes, "get_pool", new=AsyncMock(return_value=SimpleNamespace(acquire=acquire))),
            patch.object(routes, "_uses_flat_comments", new=AsyncMock(return_value=True)),
            patch.object(routes, "_flat_comment_payload", new=AsyncMock(return_value={"comment_text": "QA"})),
        )

    async def test_create_uses_verified_user_and_uuid(self):
        conn = SimpleNamespace(execute=AsyncMock(),fetchval=AsyncMock(return_value=False))
        a,b,c,d = self.context(conn)
        with a,b,c,d:
            result = await routes.create_comment("qa", routes.CreateCommentRequest(comment_text="QA"), SimpleNamespace(id="donor"))
        sql, ident, campaign, author, text = conn.execute.call_args.args
        self.assertIn("INSERT INTO comments(id,campaign_id,user_id,content", sql)
        self.assertEqual((campaign,author,text), (99,"donor","QA"))
        self.assertEqual(len(ident), 36)
        self.assertEqual(result["comment"]["comment_text"], "QA")

    async def test_private_campaign_does_not_accept_comments(self):
        conn = SimpleNamespace(execute=AsyncMock())
        a,b,c,d = self.context(conn,"suspended")
        with a,b,c,d:
            with self.assertRaises(HTTPException) as caught:
                await routes.create_comment("qa", routes.CreateCommentRequest(comment_text="QA"), SimpleNamespace(id="donor"))
        self.assertEqual(caught.exception.status_code,400)
        conn.execute.assert_not_awaited()

    async def test_edit_and_soft_delete_are_atomic_owner_and_campaign_scoped(self):
        conn = SimpleNamespace(fetchrow=AsyncMock(return_value={"id":"qa-id"}),fetchval=AsyncMock(return_value=False))
        a,b,c,d = self.context(conn)
        with a,b,c,d:
            await routes.update_comment("qa","qa-id",routes.UpdateCommentRequest(comment_text="Edited"),SimpleNamespace(id="donor"))
            await routes.delete_comment("qa","qa-id",SimpleNamespace(id="donor"))
        edit, hide = conn.fetchrow.call_args_list
        self.assertIn("campaign_id=$2 AND user_id=$3", edit.args[0])
        self.assertEqual(edit.args[1:],("qa-id",99,"donor","Edited"))
        self.assertIn("SET is_hidden=true", hide.args[0])
        self.assertEqual(hide.args[1:],("qa-id",99,"donor"))

    async def test_other_users_comment_cannot_be_edited(self):
        conn = SimpleNamespace(fetchrow=AsyncMock(return_value=None),fetchval=AsyncMock(return_value=False))
        a,b,c,d = self.context(conn)
        with a,b,c,d:
            with self.assertRaises(HTTPException) as caught:
                await routes.update_comment("qa","qa-id",routes.UpdateCommentRequest(comment_text="Edited"),SimpleNamespace(id="other"))
        self.assertEqual(caught.exception.status_code,404)

    async def test_banned_user_is_rejected_before_comment_write(self):
        conn = SimpleNamespace(execute=AsyncMock(),fetchval=AsyncMock(return_value=True))
        a,b,c,d = self.context(conn)
        with a,b,c,d:
            with self.assertRaises(HTTPException) as caught:
                await routes.create_comment("qa", routes.CreateCommentRequest(comment_text="QA"), SimpleNamespace(id="blocked"))
        self.assertEqual(caught.exception.status_code,403)
        conn.execute.assert_not_awaited()
