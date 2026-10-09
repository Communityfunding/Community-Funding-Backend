"""Encrypted submission storage contract; fake connection and non-bank test strings."""
import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
import db


class BankStorageTests(unittest.IsolatedAsyncioTestCase):
    async def test_only_ciphertext_is_passed_to_database(self):
        conn = SimpleNamespace(fetchrow=AsyncMock(return_value={"creator_id": "owner"}), execute=AsyncMock())
        data = {"routing_number": "TEST-ONLY-NOT-A-ROUTING-NUMBER",
                "account_number": "TEST-ONLY-NOT-AN-ACCOUNT", "account_holder_name": "Isolated QA"}
        with patch("app.bank_crypto.encrypt_bank_payload", return_value="encrypted-qa-blob") as encrypt:
            await db._upsert_bank_details_encrypted(conn, 99, "owner", data)
        encrypt.assert_called_once()
        insert = conn.execute.call_args.args
        self.assertIn("fermat_key", insert[0])
        self.assertEqual(insert[1:], (99, "encrypted-qa-blob", "individual"))
        self.assertNotIn(data["account_number"], str(insert))
        self.assertNotIn(data["routing_number"], str(insert))

    async def test_other_creator_cannot_store_bank_details(self):
        conn = SimpleNamespace(fetchrow=AsyncMock(return_value={"creator_id": "other"}), execute=AsyncMock())
        with self.assertRaises(ValueError):
            await db._upsert_bank_details_encrypted(conn, 99, "owner", {})
        conn.execute.assert_not_awaited()
