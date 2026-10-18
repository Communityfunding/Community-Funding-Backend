"""Explicit demo grant; run only after the project owner approves this subject.

Credentials stay in the service environment and are never printed.
"""
import argparse
import os
from pathlib import Path

import psycopg


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--email", required=True)
    parser.add_argument("--clerk-id", required=True)
    parser.add_argument("--confirmed-demo-grant", action="store_true", required=True)
    args = parser.parse_args()
    dsn = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://", 1)
    with psycopg.connect(dsn) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT name, last_name FROM public.creators WHERE creator_id=%s AND lower(email)=lower(%s)",
                           (args.clerk_id, args.email))
            creator = cursor.fetchone()
            if creator is None:
                raise SystemExit("Approved subject/email pair does not match an existing creator; no grant made.")
            # Separate schema transaction from the explicit role grant.
            connection.commit()
            migration = Path(__file__).resolve().parents[1] / "db/migrations/007_demo_site_admin_tables.sql"
            cursor.execute(migration.read_text(encoding="utf-8"), prepare=False)
            connection.commit()
            cursor.execute("""INSERT INTO public.site_admins
                (username, first_name, last_name, hashed_password, status, is_active, clerk_user_id)
                VALUES (%s, %s, %s, %s, 'approved', true, %s)
                ON CONFLICT (clerk_user_id) DO UPDATE SET status='approved', is_active=true
                RETURNING admin_id""",
                ("clerk:" + args.clerk_id, creator[0] or "Demo", creator[1] or "Admin",
                 "disabled-local-password-clerk-only", args.clerk_id))
            admin_id = cursor.fetchone()[0]
            cursor.execute("""INSERT INTO public.admin_activity_log
                (admin_id, action, target_type, target_id, details)
                VALUES (%s, 'provision_demo_admin', 'clerk_subject', %s,
                        'Human-approved demo administrator grant')""", (admin_id, args.clerk_id))
        connection.commit()
    print(f"Approved demo administrator provisioned: admin_id={admin_id}")


if __name__ == "__main__":
    main()
