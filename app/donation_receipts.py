"""Durable receipt outbox. Payment state commits before contacting Resend."""
import html
import os
from decimal import Decimal
import httpx
from sqlalchemy import text


def enabled():
    return os.getenv("DONATION_RECEIPT_EMAILS_ENABLED", "").lower() in {"1", "true"}


async def enqueue_receipt(db, donation_id):
    await db.execute(text("""
        INSERT INTO donation_receipt_emails(donation_id)
        SELECT id FROM donations WHERE id=:id AND donor_email IS NOT NULL
          AND status='SUCCEEDED'
        ON CONFLICT(donation_id) DO NOTHING
    """), {"id": donation_id})


async def deliver_receipt(db, donation_id):
    result = await db.execute(text("""
        SELECT d.id,d.donor_email,d.amount,c.title,e.provider_id
        FROM donation_receipt_emails e JOIN donations d ON d.id=e.donation_id
        JOIN campaigns c ON c.campaign_id=d.campaign_id
        WHERE d.id=:id AND d.status='SUCCEEDED'
    """), {"id": donation_id})
    row = result.mappings().first()
    if not row or row["provider_id"]:
        return "already_sent_or_not_needed"
    key = os.getenv("RESEND_API_KEY", "").strip()
    sender = os.getenv("RESEND_FROM_EMAIL", "").strip()
    if not key or not sender:
        raise RuntimeError("Receipt email configuration unavailable")
    test_mode = os.getenv("STRIPE_SECRET_KEY", "").startswith("sk_test_")
    prefix = "[SANDBOX TEST — no real charge] " if test_mode else ""
    title = str(row["title"])
    amount = f"{Decimal(str(row['amount'])):.2f}"
    payload = {
        "from": sender, "to": [row["donor_email"]],
        "subject": prefix + "Community Fundings contribution confirmation",
        "text": f"{prefix}\nYour contribution of ${amount} to {title} was recorded successfully.\nReference: {donation_id}\nThis is a payment confirmation, not a tax-deductible donation receipt.",
        "html": f"<p>{html.escape(prefix)}</p><p>Your contribution of <strong>${amount}</strong> to {html.escape(title)} was recorded successfully.</p><p>Reference: {html.escape(str(donation_id))}</p><p>This is a payment confirmation, not a tax-deductible donation receipt.</p>",
    }
    async with httpx.AsyncClient(timeout=15) as client:
        response = await client.post("https://api.resend.com/emails", json=payload, headers={
            "Authorization": f"Bearer {key}",
            "Idempotency-Key": f"community-fundings-receipt/{donation_id}",
        })
    # Do not print provider response bodies or recipient addresses.
    if response.status_code >= 300:
        raise RuntimeError("Receipt email provider temporarily unavailable")
    provider_id = response.json().get("id")
    if not provider_id:
        raise RuntimeError("Receipt provider did not acknowledge sending")
    await db.execute(text("""
        UPDATE donation_receipt_emails SET provider_id=:provider_id, sent_at=NOW()
        WHERE donation_id=:id AND provider_id IS NULL
    """), {"id": donation_id, "provider_id": provider_id})
    await db.commit()
    return "accepted_by_provider"
