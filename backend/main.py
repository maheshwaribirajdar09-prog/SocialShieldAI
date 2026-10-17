from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import dotenv_values
import requests
import os
import sys
import hashlib
import secrets


# ============================================================
# PATH SETUP
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(BASE_DIR, ".env")
PROJECT_ROOT = os.path.dirname(BASE_DIR)

sys.path.insert(0, PROJECT_ROOT)


# ============================================================
# ENVIRONMENT VARIABLES
# ============================================================

env = dotenv_values(ENV_PATH)

X_BEARER_TOKEN = env.get("X_BEARER_TOKEN")


# ============================================================
# PROJECT IMPORTS
# ============================================================

from database import create_tables, get_connection, save_scan
from ml.predict import detect_profile


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(
    title="SocialShieldAI Backend",
    description="Backend for X Profile Detection",
    version="1.0"
)


# ============================================================
# CREATE DATABASE TABLES
# ============================================================

create_tables()


# ============================================================
# REQUEST MODELS
# ============================================================

class PredictRequest(BaseModel):
    username: str
    user_id: int


class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    email: str
    new_password: str


# ============================================================
# PASSWORD HELPERS
# ============================================================

def hash_password(password: str, salt: str | None = None):

    if salt is None:
        salt = secrets.token_hex(16)

    hashed = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        100000
    )

    return f"{salt}${hashed.hex()}"


def verify_password(password: str, stored_password: str):

    try:
        salt, stored_hash = stored_password.split("$", 1)

        hashed = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            salt.encode("utf-8"),
            100000
        ).hex()

        return secrets.compare_digest(hashed, stored_hash)

    except Exception:
        return False


# ============================================================
# X PROFILE API
# ============================================================

def get_x_profile(username: str):

    username = username.strip().lstrip("@")

    if not username:
        raise HTTPException(
            status_code=400,
            detail="Username is required."
        )

    if not X_BEARER_TOKEN:
        raise HTTPException(
            status_code=500,
            detail="X_BEARER_TOKEN is not configured."
        )

    url = f"https://api.x.com/2/users/by/username/{username}"

    headers = {
        "Authorization": f"Bearer {X_BEARER_TOKEN}"
    }

    params = {
        "user.fields": (
            "description,"
            "created_at,"
            "profile_image_url,"
            "protected,"
            "public_metrics"
        )
    }

    try:

        response = requests.get(
            url,
            headers=headers,
            params=params,
            timeout=15
        )

    except requests.RequestException as e:

        raise HTTPException(
            status_code=503,
            detail=f"Could not connect to X API: {str(e)}"
        )

    if response.status_code != 200:

        raise HTTPException(
            status_code=response.status_code,
            detail=f"X API error: {response.text}"
        )

    data = response.json()

    if "data" not in data:

        raise HTTPException(
            status_code=404,
            detail="X profile not found."
        )

    return data["data"]


# ============================================================
# PREPARE ML FEATURES
# ============================================================

def prepare_ml_features(profile):

    username = profile.get("username", "")

    description = profile.get(
        "description",
        ""
    ) or ""

    public_metrics = profile.get(
        "public_metrics",
        {}
    ) or {}

    followers = public_metrics.get(
        "followers_count",
        0
    )

    following = public_metrics.get(
        "following_count",
        0
    )

    media_count = public_metrics.get(
        "tweet_count",
        0
    )

    has_profile_picture = (
        1 if profile.get("profile_image_url") else 0
    )

    is_private = (
        1 if profile.get("protected", False) else 0
    )

    username_digit_count = sum(
        character.isdigit()
        for character in username
    )

    username_length = len(username)

    biography_length = len(description)

    return (
        followers,
        following,
        biography_length,
        media_count,
        has_profile_picture,
        is_private,
        username_digit_count,
        username_length
    )


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():

    return {
        "message": "SocialShieldAI Backend is running"
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
def health():

    return {
        "status": "OK"
    }


# ============================================================
# REGISTER
# ============================================================

@app.post("/register")
def register(request: RegisterRequest):

    username = request.username.strip()
    email = request.email.strip().lower()
    password = request.password

    if not username:
        raise HTTPException(
            status_code=400,
            detail="Username is required."
        )

    if not email:
        raise HTTPException(
            status_code=400,
            detail="Email is required."
        )

    if not password:
        raise HTTPException(
            status_code=400,
            detail="Password is required."
        )

    connection = get_connection()
    cursor = connection.cursor()

    try:

        cursor.execute(
            """
            SELECT id
            FROM users
            WHERE username = ? OR email = ?
            """,
            (username, email)
        )

        existing_user = cursor.fetchone()

        if existing_user:

            raise HTTPException(
                status_code=409,
                detail="Username or email already exists."
            )

        hashed_password = hash_password(password)

        cursor.execute(
            """
            INSERT INTO users
            (username, email, password)
            VALUES (?, ?, ?)
            """,
            (
                username,
                email,
                hashed_password
            )
        )

        connection.commit()

        user_id = cursor.lastrowid

        return {
            "message": "Registration successful.",
            "user_id": user_id,
            "username": username,
            "email": email
        }

    finally:

        connection.close()


# ============================================================
# LOGIN
# ============================================================

@app.post("/login")
def login(request: LoginRequest):

    email = request.email.strip().lower()
    password = request.password

    connection = get_connection()
    cursor = connection.cursor()

    try:

        cursor.execute(
            """
            SELECT id, username, email, password
            FROM users
            WHERE email = ?
            """,
            (email,)
        )

        user = cursor.fetchone()

        if not user:

            raise HTTPException(
                status_code=401,
                detail="Invalid email or password."
            )

        if not verify_password(
            password,
            user["password"]
        ):

            raise HTTPException(
                status_code=401,
                detail="Invalid email or password."
            )

        return {
            "message": "Login successful.",
            "user_id": user["id"],
            "username": user["username"],
            "email": user["email"]
        }

    finally:

        connection.close()


# ============================================================
# FORGOT PASSWORD
# ============================================================

@app.post("/forgot-password")
def forgot_password(
    request: ForgotPasswordRequest
):

    email = request.email.strip().lower()

    connection = get_connection()
    cursor = connection.cursor()

    try:

        cursor.execute(
            """
            SELECT id
            FROM users
            WHERE email = ?
            """,
            (email,)
        )

        user = cursor.fetchone()

        if not user:

            raise HTTPException(
                status_code=404,
                detail="Email not found."
            )

        return {
            "message": "Email verified. You can reset your password."
        }

    finally:

        connection.close()


# ============================================================
# RESET PASSWORD
# ============================================================

@app.post("/reset-password")
def reset_password(
    request: ResetPasswordRequest
):

    email = request.email.strip().lower()
    new_password = request.new_password

    if not new_password:

        raise HTTPException(
            status_code=400,
            detail="New password is required."
        )

    connection = get_connection()
    cursor = connection.cursor()

    try:

        cursor.execute(
            """
            SELECT id
            FROM users
            WHERE email = ?
            """,
            (email,)
        )

        user = cursor.fetchone()

        if not user:

            raise HTTPException(
                status_code=404,
                detail="Email not found."
            )

        hashed_password = hash_password(
            new_password
        )

        cursor.execute(
            """
            UPDATE users
            SET password = ?
            WHERE email = ?
            """,
            (
                hashed_password,
                email
            )
        )

        connection.commit()

        return {
            "message": "Password reset successful."
        }

    finally:

        connection.close()


# ============================================================
# PREDICT X PROFILE
# ============================================================

@app.post("/predict")
def predict(request: PredictRequest):

    # --------------------------------------------------------
    # STEP 1: Check logged-in user
    # --------------------------------------------------------

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute(
        """
        SELECT id, username
        FROM users
        WHERE id = ?
        """,
        (request.user_id,)
    )

    user = cursor.fetchone()

    connection.close()

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User account not found."
        )

    # --------------------------------------------------------
    # STEP 2: Get X profile
    # --------------------------------------------------------

    profile = get_x_profile(
        request.username
    )

    # --------------------------------------------------------
    # STEP 3: Prepare ML features
    # --------------------------------------------------------

    features = prepare_ml_features(
        profile
    )

    (
        followers,
        following,
        biography_length,
        media_count,
        has_profile_picture,
        is_private,
        username_digit_count,
        username_length
    ) = features

    # --------------------------------------------------------
    # STEP 4: Run ML model
    # --------------------------------------------------------

    prediction, confidence, confidence_level, risk_factors = detect_profile(
        followers,
        following,
        biography_length,
        media_count,
        has_profile_picture,
        is_private,
        username_digit_count,
        username_length
    )

    # --------------------------------------------------------
    # STEP 5: Save scan history
    # --------------------------------------------------------

    save_scan(
        request.user_id,
        profile.get("username", request.username),
        f"https://x.com/{profile.get('username', request.username)}",
        prediction,
        confidence
    )

    # --------------------------------------------------------
    # STEP 6: Return result to Flutter
    # --------------------------------------------------------

    return {
        "username": profile.get(
            "username",
            request.username
        ),

        "name": profile.get(
            "name",
            ""
        ),

        "profileUrl": (
            f"https://x.com/"
            f"{profile.get('username', request.username)}"
        ),

        "followers": followers,

        "following": following,

        "biography": profile.get(
            "description",
            ""
        ) or "",

        "mediaCount": media_count,

        "hasProfilePicture": bool(
            has_profile_picture
        ),

        "isPrivate": bool(
            is_private
        ),

        "prediction": prediction,

        "confidence": confidence,

        "confidenceLevel": confidence_level,

        "riskFactors": risk_factors
    }


# ============================================================
# GET SCAN HISTORY
# ============================================================

@app.get("/history/{user_id}")
def get_scan_history(user_id: int):

    connection = get_connection()
    cursor = connection.cursor()

    try:

        cursor.execute(
            """
            SELECT
                id,
                user_id,
                x_username,
                profile_url,
                result,
                confidence,
                scanned_at
            FROM scan_history
            WHERE user_id = ?
            ORDER BY scanned_at DESC
            """,
            (user_id,)
        )

        rows = cursor.fetchall()

        history = []

        for row in rows:

            history.append(
                {
                    "id": row["id"],
                    "user_id": row["user_id"],
                    "x_username": row["x_username"],
                    "profile_url": row["profile_url"],
                    "result": row["result"],
                    "confidence": row["confidence"],
                    "scanned_at": row["scanned_at"]
                }
            )

        return {
            "user_id": user_id,
            "total_scans": len(history),
            "history": history
        }

    finally:

        connection.close()