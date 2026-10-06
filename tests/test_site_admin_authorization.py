"""Isolated tests: no real users, database, Clerk requests or role grants."""
import unittest
from unittest.mock import patch

from fastapi import HTTPException
from fastapi import FastAPI
from fastapi.testclient import TestClient
from starlette.requests import Request

from app.site_admin_auth import authenticated_site_admin_id, guard_site_admin_routes
from app.routes.site_admin import router, _log
from app.database import get_db


class Result:
    def __init__(self, value):
        self.value = value

    def scalar(self):
        return self.value

    def mappings(self):
        return self

    def first(self):
        return self.value


class Database:
    def __init__(self, values=()):
        self.values = iter(values)
        self.calls = 0

    async def execute(self, *args, **kwargs):
        self.calls += 1
        return Result(next(self.values))


def request(token=None, query="", path="/api/site-admin/dashboard"):
    headers = [] if token is None else [(b"authorization", token.encode())]
    return Request({"type": "http", "method": "GET", "path": path,
                    "query_string": query.encode(), "headers": headers})


class SiteAdminAuthorizationTests(unittest.IsolatedAsyncioTestCase):
    async def assert_denied(self, req, db, status, **patches):
        with patch("jwt_utils.DEV_JWT_BYPASS", patches.get("bypass", False)), \
             patch("jwt_utils.verify_token", return_value=patches.get("claims", {"sub": "ordinary-user"}),
                   side_effect=patches.get("error")):
            with self.assertRaises(HTTPException) as caught:
                await authenticated_site_admin_id(req, db)
            self.assertEqual(caught.exception.status_code, status)

    async def test_query_id_without_token_cannot_authenticate(self):
        db = Database()
        await self.assert_denied(request(query="admin_id=1"), db, 401)
        self.assertEqual(db.calls, 0)

    async def test_invalid_signature_is_rejected_before_database(self):
        db = Database()
        await self.assert_denied(request("Bearer forged"), db, 401, error=ValueError("signature"))
        self.assertEqual(db.calls, 0)

    async def test_dev_bypass_cannot_grant_admin_authority(self):
        await self.assert_denied(request("Bearer test"), Database(), 503, bypass=True)

    async def test_missing_subject_is_rejected(self):
        await self.assert_denied(request("Bearer test"), Database(), 401, claims={})

    async def test_unprovisioned_database_fails_closed(self):
        await self.assert_denied(request("Bearer test"), Database([None]), 403)

    async def test_legacy_admin_without_identity_link_fails_closed(self):
        await self.assert_denied(request("Bearer test"), Database(["site_admins", None]), 403)

    async def test_ordinary_user_cannot_become_admin(self):
        await self.assert_denied(request("Bearer test"), Database(["site_admins", 1, None]), 403)

    async def test_valid_admin_cannot_impersonate_other_admin(self):
        await self.assert_denied(request("Bearer test", "admin_id=99"),
                                 Database(["site_admins", 1, {"admin_id": 7}]), 403)

    async def test_approved_subject_can_use_own_admin_id(self):
        with patch("jwt_utils.DEV_JWT_BYPASS", False), \
             patch("jwt_utils.verify_token", return_value={"sub": "approved-admin"}):
            result = await authenticated_site_admin_id(request("Bearer test", "admin_id=7"),
                         Database(["site_admins", 1, {"admin_id": 7}]))
        self.assertEqual(result, 7)

    async def test_guard_covers_mutating_routes(self):
        await self.assert_denied(request(query="admin_id=1", path="/api/site-admin/campaigns/2/approve"),
                                 Database(), 401)
        with self.assertRaises(HTTPException) as caught:
            await guard_site_admin_routes(request(path="/api/site-admin/users/user-x/block"), Database())
        self.assertEqual(caught.exception.status_code, 401)

    async def test_audit_failure_blocks_moderation(self):
        class FailingDatabase:
            async def execute(self, *args, **kwargs):
                raise RuntimeError("Audit table unavailable")
        with self.assertRaises(HTTPException) as caught:
            await _log(FailingDatabase(), 7, "approve_campaign", "campaign", "2")
        self.assertEqual(caught.exception.status_code, 503)


class SiteAdminRouterTests(unittest.TestCase):
    def setUp(self):
        self.db = Database()
        application = FastAPI()
        application.include_router(router)

        async def fake_db():
            yield self.db

        application.dependency_overrides[get_db] = fake_db
        self.client = TestClient(application)

    def test_public_registration_cannot_create_administrator(self):
        response = self.client.post("/api/site-admin/register", json={
            "username": "fake-code", "first_name": "QA", "last_name": "Test"
        })
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self.db.calls, 0)

    def test_legacy_access_code_alone_cannot_log_in(self):
        response = self.client.post("/api/site-admin/login", json={
            "username": "fake-code", "first_name": "QA", "last_name": "Test"
        })
        self.assertEqual(response.status_code, 401)
        self.assertEqual(self.db.calls, 0)

    def test_all_read_endpoints_reject_query_id_without_session(self):
        for endpoint in ("dashboard", "campaigns", "users", "reports", "transactions",
                         "activity", "pending-campaigns"):
            with self.subTest(endpoint=endpoint):
                response = self.client.get(f"/api/site-admin/{endpoint}?admin_id=1")
                self.assertEqual(response.status_code, 401)
        self.assertEqual(self.db.calls, 0)

    def test_campaign_moderation_rejects_query_id_without_session(self):
        for action in ("approve", "suspend", "reinstate", "delete"):
            with self.subTest(action=action):
                response = self.client.post(f"/api/site-admin/campaigns/2/{action}?admin_id=1")
                self.assertEqual(response.status_code, 401)
        self.assertEqual(self.db.calls, 0)
