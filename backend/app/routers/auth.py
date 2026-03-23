"""
app/routers/auth.py
===================
JWT-based authentication with role-based access control.

Endpoints:
  POST /auth/register   — create a new user (admin only)
  POST /auth/login      — returns access token
  GET  /auth/me         — returns current user info

Usage in protected routes:
  from app.routers.auth import require_admin, require_teacher, get_current_user

  @router.post("/something")
  def endpoint(current_user = Depends(require_admin)):
      ...
"""
import os
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
import bcrypt
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User

router = APIRouter(prefix="/auth", tags=["Auth"])

# ── Config ────────────────────────────────────────────────────────────────
SECRET_KEY      = os.getenv("JWT_SECRET_KEY", "CHANGE_ME_IN_PRODUCTION_USE_STRONG_KEY")
ALGORITHM       = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "480"))  # 8 hours

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


# ── Pydantic schemas (local to auth) ──────────────────────────────────────
class Token(BaseModel):
    access_token: str
    token_type:   str
    role:         str
    username:     str


class UserCreate(BaseModel):
    username:  str
    password:  str
    role:      str          # "admin" | "teacher" | "student"
    linked_id: Optional[str] = None


class UserOut(BaseModel):
    user_id:   int
    username:  str
    role:      str
    linked_id: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


# ── Helpers ───────────────────────────────────────────────────────────────
def _hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def _verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode('utf-8'), hashed.encode('utf-8'))
    except ValueError:
        return False


def _create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire    = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db:    Session = Depends(get_db),
) -> User:
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload  = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise credentials_exc
    except JWTError:
        raise credentials_exc

    user = db.query(User).filter_by(username=username, is_active=True).first()
    if user is None:
        raise credentials_exc
    return user


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user


def require_teacher(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role not in ("admin", "teacher"):
        raise HTTPException(status_code=403, detail="Teacher or admin access required")
    return current_user


# ── Endpoints ─────────────────────────────────────────────────────────────
@router.post("/login", response_model=Token, summary="Get access token")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db:        Session = Depends(get_db),
):
    user = db.query(User).filter_by(username=form_data.username, is_active=True).first()
    if not user or not _verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = _create_access_token(
        data={"sub": user.username, "role": user.role},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return Token(access_token=token, token_type="bearer",
                 role=user.role, username=user.username)


@router.post(
    "/register",
    response_model=UserOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new user (admin only)",
)
def register(
    body:         UserCreate,
    db:           Session = Depends(get_db),
    _admin:       User    = Depends(require_admin),
):
    if body.role not in ("admin", "teacher", "student"):
        raise HTTPException(status_code=400, detail="role must be admin, teacher, or student")
    if db.query(User).filter_by(username=body.username).first():
        raise HTTPException(status_code=409, detail="Username already exists")

    user = User(
        username        = body.username,
        hashed_password = _hash_password(body.password),
        role            = body.role,
        linked_id       = body.linked_id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/me", response_model=UserOut, summary="Get current user info")
def me(current_user: User = Depends(get_current_user)):
    return current_user


@router.delete("/{user_id}", summary="Deactivate a user (admin only)")
def deactivate_user(
    user_id: int,
    db:      Session = Depends(get_db),
    _admin:  User    = Depends(require_admin),
):
    user = db.query(User).filter_by(user_id=user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    db.commit()
    return {"message": f"User {user.username} deactivated"}
