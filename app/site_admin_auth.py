"""Site-wide admin authorization is a server-side grant, never a query ID."""

from fastapi import Depends, HTTPException, Request
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
import jwt_utils


async def authenticated_site_admin_id(
    request: Request, db: AsyncSession = Depends(get_db)
) -> int:
    authorization = request.headers.get("authorization", "")
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise HTTPException(status_code=401, detail="Clerk sign-in required")
    # Never turn a local development bypass into platform-wide authority.
    if jwt_utils.DEV_JWT_BYPASS:
        raise HTTPException(status_code=503, detail="Admin authentication is not configured securely")
    try:
        claims = jwt_utils.verify_token(token.strip())
        subject = (claims or {}).get("sub")
        if not subject:
            raise ValueError("Missing subject")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired Clerk session") from None

    # Missing provisioning is denied rather than enabling a public bootstrap.
    table = (await db.execute(text("SELECT to_regclass('public.site_admins')"))).scalar()
    if table is None:
        raise HTTPException(status_code=403, detail="No administrator access has been provisioned")
    column = (await db.execute(text(
        "SELECT 1 FROM information_schema.columns WHERE table_schema='public' "
        "AND table_name='site_admins' AND column_name='clerk_user_id'"
    ))).scalar()
    if not column:
        raise HTTPException(status_code=403, detail="Administrator identity linkage is required")
    row = (await db.execute(text(
        "SELECT admin_id FROM public.site_admins "
        "WHERE clerk_user_id = :subject AND is_active = true AND status = 'approved'"
    ), {"subject": subject})).mappings().first()
    if row is None:
        raise HTTPException(status_code=403, detail="Administrator access required")
    admin_id = int(row["admin_id"])
    supplied_id = request.query_params.get("admin_id")
    if supplied_id is not None and supplied_id != str(admin_id):
        raise HTTPException(status_code=403, detail="Administrator identity mismatch")
    return admin_id


async def guard_site_admin_routes(request: Request, db: AsyncSession = Depends(get_db)):
    # Login verifies its own identity. Registration always rejects requests.
    if request.url.path.rstrip("/") in {"/api/site-admin/login", "/api/site-admin/register"}:
        return
    request.state.site_admin_id = await authenticated_site_admin_id(request, db)
