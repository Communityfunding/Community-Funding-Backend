"""Isolated route contracts; never change a live campaign or grant roles."""
import unittest
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from app.routes import site_admin


class Result:
    def __init__(self, value):
        self.value = value

    def mappings(self):
        return self

    def first(self):
        return self.value

    def all(self):
        return self.value

    def scalar(self):
        return self.value


class Database:
    def __init__(self, values):
        self.values = iter(values)
        self.queries = []
        self.commit = AsyncMock()

    async def execute(self, query, params=None):
        self.queries.append((str(query), params))
        return Result(next(self.values))


class AdminQueryTests(unittest.IsolatedAsyncioTestCase):
    async def test_transaction_query_uses_real_columns_and_normalizes_enum(self):
        db = Database([[], 0, {"total": 0, "fees": 0, "count": 0}])
        with patch.object(site_admin, "_verify_admin", new=AsyncMock()):
            response = await site_admin.list_transactions(1, status="SUCCEEDED", db=db)
        sql, params = db.queries[0]
        self.assertIn("d.id AS donation_id", sql)
        self.assertIn("d.created_at AS time_created", sql)
        self.assertIn("LOWER(d.status::TEXT)", sql)
        self.assertEqual(params["st"], "succeeded")
        self.assertEqual(response["transactions"], [])

    async def test_approval_only_updates_pending_and_audits_before_commit(self):
        db = Database([{"campaign_id": 99, "title": "Isolated QA"}, None])
        with patch.object(site_admin, "_verify_admin", new=AsyncMock()):
            response = await site_admin.approve_campaign(99, 1, db)
        self.assertIn("status = 'pending_review'", db.queries[0][0])
        self.assertIn("reviewed_by = :aid", db.queries[0][0])
        self.assertIn("INSERT INTO admin_activity_log", db.queries[1][0])
        db.commit.assert_awaited_once()
        self.assertEqual(response["status"], "approved")

    async def test_draft_or_already_reviewed_cannot_be_approved(self):
        db = Database([None])
        with patch.object(site_admin, "_verify_admin", new=AsyncMock()):
            with self.assertRaises(HTTPException) as caught:
                await site_admin.approve_campaign(99, 1, db)
        self.assertEqual(caught.exception.status_code, 404)
        db.commit.assert_not_awaited()

    async def test_rejection_persists_reason_and_audits(self):
        db = Database([{"campaign_id": 99, "title": "Isolated QA"}, None])
        with patch.object(site_admin, "_verify_admin", new=AsyncMock()):
            response = await site_admin.reject_campaign(
                99, 1, site_admin.RejectCampaign(reason="QA rejection"), db)
        self.assertEqual(db.queries[0][1]["reason"], "QA rejection")
        self.assertIn("status = 'pending_review'", db.queries[0][0])
        self.assertEqual(db.queries[1][1]["a"], "reject_campaign")
        self.assertEqual(response["status"], "rejected")
        db.commit.assert_awaited_once()
