"""Isolated permission matrix checks; no live identities, grants or DB writes."""
import unittest
from unittest.mock import AsyncMock, patch
from fastapi import HTTPException
from app.routes import organizations


class Connection:
    def __init__(self, role):
        self.role = role

    async def fetchrow(self, *args):
        return None if self.role is None else {"role": self.role}


class Acquisition:
    def __init__(self, role):
        self.connection = Connection(role)

    async def __aenter__(self):
        return self.connection

    async def __aexit__(self, *args):
        return False


class Pool:
    def __init__(self, role):
        self.role = role

    def acquire(self):
        return Acquisition(self.role)


class OrganizationRoleChecks(unittest.IsolatedAsyncioTestCase):
    async def check_role(self, role, allowed, should_allow):
        with patch.object(organizations.db_mod, "get_pool", new=AsyncMock(return_value=Pool(role))):
            if should_allow:
                self.assertEqual(await organizations._require_role("fixture-org", "fixture-person", allowed), role)
            else:
                with self.assertRaises(HTTPException) as caught:
                    await organizations._require_role("fixture-org", "fixture-person", allowed)
                self.assertEqual(caught.exception.status_code, 403)

    async def test_finance_matrix(self):
        for role in ("owner", "admin", "finance", "campaign_editor", "viewer"):
            with self.subTest(role=role):
                await self.check_role(role, organizations.FINANCE_ROLES, role in {"owner", "admin", "finance"})

    async def test_campaign_edit_matrix(self):
        for role in ("owner", "admin", "finance", "campaign_editor", "viewer"):
            with self.subTest(role=role):
                await self.check_role(role, organizations.CAMPAIGN_EDIT_ROLES, role in {"owner", "admin", "campaign_editor"})

    async def test_team_management_owner_only(self):
        for role in ("owner", "admin", "finance", "campaign_editor", "viewer"):
            with self.subTest(role=role):
                await self.check_role(role, {"owner"}, role == "owner")

    async def test_nonmember_unknown_role_fail_closed(self):
        for role in (None, "unknown"):
            with self.subTest(role=role):
                await self.check_role(role, organizations.FINANCE_ROLES, False)
