from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from dotenv import dotenv_values
import requests
import os


# =========================================================
# LOAD X BEARER TOKEN
# =========================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(BASE_DIR, ".env")

env = dotenv_values(ENV_PATH)

X_BEARER_TOKEN = env.get("X_BEARER_TOKEN")

if not X_BEARER_TOKEN:
    raise RuntimeError(
        f"X_BEARER_TOKEN is missing from: {ENV_PATH}"
    )


# =========================================================
# FASTAPI APP
# =========================================================

app = FastAPI(
    title="SocialShieldAI API",
    description="X Profile Analysis API for SocialShieldAI",
    version="1.0.0"
)


# =========================================================
# CORS
# =========================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =========================================================
# HOME / HEALTH CHECK
# =========================================================

@app.get("/")
def home():
    return {
        "message": "SocialShieldAI API is running",
        "status": "OK"
    }


# =========================================================
# GET X PROFILE
# =========================================================

def get_x_profile(username: str):

    username = username.strip().lstrip("@")

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


# =========================================================
# TEST X PROFILE
# =========================================================

@app.get("/test-x/{username}")
def test_x(username: str):

    profile = get_x_profile(username)

    return {
        "message": "X API connection successful",
        "profile": profile
    }