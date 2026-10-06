"""Human-authorized demo setup. Secrets stay in memory and Railway stdin.

Does not create campaigns, charge cards or modify live Stripe configuration.
Preserves an already-configured strong JWT key. Stable webhook idempotency
key allows recovery if creation succeeds but a later variable update fails.
"""
import json
import secrets
import subprocess
import shutil
import stripe

PROJECT = "58ee7caf-3ce8-44eb-acfd-e3b58b97926d"
SERVICE = "b29b94cf-86b2-49f1-b5fe-d38a4ca3e8bd"
ENVIRONMENT = "984f39c2-9b19-43ec-987b-b5c7ca39bfa4"
SCOPE = ["--project", PROJECT, "--service", SERVICE, "--environment", ENVIRONMENT]
URL = "https://communityfundingsbackend-production.up.railway.app/api/donations-v2/webhook"
DESCRIPTION = "Community Fundings demo Checkout test webhook (authorized 2026-10-06)"
RAILWAY = shutil.which("railway")


def set_secret(name, value):
    for _ in range(3):
        result = subprocess.run([RAILWAY, "variable", "set", name, "--stdin", "--skip-deploys", *SCOPE],
                                input=value, text=True, capture_output=True)
        if result.returncode == 0:
            return
    raise RuntimeError("Secret update failed; no secret output")


def main():
    raw = subprocess.run([RAILWAY, "variables", *SCOPE, "--json"], text=True, capture_output=True, check=True)
    variables = json.loads(raw.stdout)
    stripe_key = variables.get("STRIPE_SECRET_KEY", "")
    if not stripe_key.startswith("sk_test_"):
        raise RuntimeError("Refusing: Stripe test key required")
    existing_key = variables.get("JWT_SECRET_KEY", "")
    changed = len(existing_key) < 32 or existing_key in ("dev-secret-change-me-in-production", "local-dev-only")
    if changed:
        set_secret("JWT_SECRET_KEY", secrets.token_urlsafe(48))
    stripe.api_key = stripe_key
    matches = [e for e in stripe.WebhookEndpoint.list(limit=100).data if e.url == URL]
    if any(e.description != DESCRIPTION for e in matches):
        raise RuntimeError("Unexpected existing webhook; inspect before changing it")
    endpoint = stripe.WebhookEndpoint.create(
        url=URL, enabled_events=["checkout.session.completed", "checkout.session.expired"],
        description=DESCRIPTION,
        idempotency_key="communityfundings-demo-checkout-webhook-20261006")
    if endpoint.livemode:
        raise RuntimeError("Refusing live-mode webhook")
    set_secret("STRIPE_WEBHOOK_SECRET", endpoint.secret)
    print(json.dumps({"jwt_key_configured": True, "jwt_key_changed": changed,
                      "stripe_webhook_configured": True, "stripe_live_mode": False,
                      "webhook_endpoint_id": endpoint.id, "backend_restart_required": True}))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Demo setup failed ({type(error).__name__}); credentials have not been printed. Inspect scoped integration state before retrying.")
        raise SystemExit(1) from None
