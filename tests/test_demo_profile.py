"""Profile visibility/query boundaries; no real account or database calls."""
import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from app.routes import profile_page


class Connection:
    def __init__(self):
        self.queries = []

    async def fetchrow(self, sql, *args):
        return {"creator_id": "owner", "email": "private@example.test", "username": "owner"}

    async def fetch(self, sql, *args):
        self.queries.append((sql, args))
        if "WHERE c.creator_id = $1" in sql:
            return [{"campaign_id": 99, "title": "Private draft", "status": "draft"}] if args[1] else []
        return []


class Context:
    def __init__(self, conn):
        self.conn = conn

    async def __aenter__(self):
        return self.conn

    async def __aexit__(self, *args):
        pass


class ProfileTests(unittest.IsolatedAsyncioTestCase):
    async def load(self, viewer):
        conn = Connection()
        pool = SimpleNamespace(acquire=lambda: Context(conn))
        with patch.object(profile_page, "get_pool", new=AsyncMock(return_value=pool)):
            result = await profile_page.get_profile_page("owner", viewer)
        return conn, result

    async def test_public_profile_filters_drafts_and_email(self):
        conn, result = await self.load(None)
        self.assertNotIn("email", result["creator"])
        self.assertEqual(result["campaigns"], [])
        sql, args = conn.queries[1]
        self.assertIn("$2::bool OR c.status IN ('active', 'inactive')", sql)
        self.assertFalse(args[1])
        activity_sql, activity_args = conn.queries[-1]
        self.assertIn("c.id AS comment_id", activity_sql)
        self.assertIn("c.created_at AS activity_time", activity_sql)
        self.assertIn("WHERE $3::bool OR campaign_status IS NULL", activity_sql)
        self.assertFalse(activity_args[2])

    async def test_other_logged_in_user_is_not_owner(self):
        conn, result = await self.load(SimpleNamespace(id="other"))
        self.assertEqual(result["campaigns"], [])
        self.assertNotIn("email", result["creator"])

    async def test_owner_retains_private_campaign_and_email(self):
        conn, result = await self.load(SimpleNamespace(id="owner"))
        self.assertEqual(result["campaigns"][0]["status"], "draft")
        self.assertEqual(result["creator"]["email"], "private@example.test")
