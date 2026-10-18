"""Clerk identity bridge must not grant sessions from client-only identity data."""
import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from fastapi import HTTPException
from app.routes import auth
from app.models.schemas import LoginRequest


class BridgeTests(unittest.IsolatedAsyncioTestCase):
    def body(self):
        return auth.ClerkSyncRequest(clerk_id="user_qa", email="qa@example.test", name="QA")

    async def test_missing_clerk_session_cannot_mint_backend_session(self):
        db = SimpleNamespace(execute=AsyncMock())
        with self.assertRaises(HTTPException) as caught:
            await auth.clerk_sync(self.body(), db, None)
        self.assertEqual(caught.exception.status_code, 401)
        db.execute.assert_not_awaited()

    async def test_verified_existing_user_can_refresh_backend_session(self):
        user = SimpleNamespace(id="user_qa", email="qa@example.test", user_type=1)
        db = SimpleNamespace(execute=AsyncMock(return_value=SimpleNamespace(
            scalar_one_or_none=lambda: user)), flush=AsyncMock())
        with patch("jwt_utils.DEV_JWT_BYPASS", False), \
             patch("jwt_utils.verify_token", return_value={"sub": "user_qa"}), \
             patch.object(auth, "create_access_token", return_value="isolated-session") as mint:
            response = await auth.clerk_sync(self.body(), db, "Bearer verified-isolated-session")
        mint.assert_called_once_with("user_qa")
        self.assertEqual(response["user_id"], "user_qa")
        db.flush.assert_awaited_once()

    async def test_clerk_subject_cannot_impersonate_another_identity(self):
        db = SimpleNamespace(execute=AsyncMock())
        with patch("jwt_utils.DEV_JWT_BYPASS", False), \
             patch("jwt_utils.verify_token", return_value={"sub": "different-user"}):
            with self.assertRaises(HTTPException) as caught:
                await auth.clerk_sync(self.body(), db, "Bearer isolated")
        self.assertEqual(caught.exception.status_code, 401)
        db.execute.assert_not_awaited()

    async def test_email_collision_does_not_merge_other_account(self):
        db = SimpleNamespace(execute=AsyncMock(side_effect=[
            SimpleNamespace(scalar_one_or_none=lambda: None),
            SimpleNamespace(scalar_one_or_none=lambda: SimpleNamespace(id="another-user"))]),
            delete=AsyncMock(), flush=AsyncMock())
        with patch("jwt_utils.DEV_JWT_BYPASS", False), \
             patch("jwt_utils.verify_token", return_value={"sub": "user_qa"}):
            with self.assertRaises(HTTPException) as caught:
                await auth.clerk_sync(self.body(), db, "Bearer isolated")
        self.assertEqual(caught.exception.status_code, 409)
        db.delete.assert_not_awaited()
        db.flush.assert_not_awaited()

    async def test_clerk_account_cannot_use_predictable_native_password(self):
        db = SimpleNamespace(execute=AsyncMock(return_value=SimpleNamespace(
            scalar_one_or_none=lambda: SimpleNamespace(id="user_qa", hashed_password="unused"))))
        with patch.object(auth, "verify_password") as check:
            with self.assertRaises(HTTPException) as caught:
                await auth.login(LoginRequest(email="qa@example.com", password="clerk_synced_qa@example.com"), db)
        self.assertEqual(caught.exception.status_code, 401)
        check.assert_not_called()
