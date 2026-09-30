from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import dotenv_values
import requests
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(BASE_DIR, ".env")

env = dotenv_values(ENV_PATH)
X_BEARER_TOKEN = env.get("X_BEARER_TOKEN")
from database import create_tables

import sys

sys.path.insert(
    0,
    r"C:\Users\sanskruti\OneDrive\Desktop\SocialShieldAI\ml"
)

from predict import detect_profile
app = FastAPI(
    title="SocialShieldAI Backend",
    description="Backend for X Profile Detection",
    version="1.0"
)


# Initialize SQLite database
create_tables()


# ============================================================
# REQUEST MODEL
# ============================================================

class PredictRequest(BaseModel):
    username: str

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

def profile_to_ml_features(profile: dict):
    username = profile.get("username", "")

    public_metrics = profile.get("public_metrics") or {}

    followers = public_metrics.get("followers_count", 0)
    following = public_metrics.get("following_count", 0)
    media_count = public_metrics.get("tweet_count", 0)

    biography = profile.get("description") or ""

    profile_picture = 1 if profile.get("profile_image_url") else 0

    is_private = 1 if profile.get("protected") else 0

    username_digit_count = sum(
        character.isdigit()
        for character in username
    )

    username_length = len(username)

    return {
        "userFollowerCount": followers,
        "userFollowingCount": following,
        "userBiographyLength": len(biography),
        "userMediaCount": media_count,
        "userHasProfilPic": profile_picture,
        "userIsPrivate": is_private,
        "usernameDigitCount": username_digit_count,
        "usernameLength": username_length
    }

def analyze_profile_with_ml(profile: dict):
    features = profile_to_ml_features(profile)

    result, confidence, confidence_level, risk_factors = detect_profile(
        **features
    )

    return {
        "prediction": result,
        "confidence": float(confidence),
        "confidence_level": confidence_level,
        "risk_factors": risk_factors
    }


# ============================================================
# HOME
# ============================================================

@app.get("/")
def home():
    return {
        "message": "SocialShieldAI Backend is running"
    }


# ============================================================
# HEALTH
# ============================================================

@app.get("/health")
def health():
    return {
        "status": "OK"
    }


# ============================================================
# PREDICT
# ============================================================

@app.post("/predict")
def predict(request: PredictRequest):

    username = request.username.strip().lstrip("@")

    if not username:
        return {
            "error": "Username is required"
        }

    profile = get_x_profile(username)

    result = analyze_profile_with_ml(profile)

    features = profile_to_ml_features(profile)

    return {
        "username": username,
        "followers": features["userFollowerCount"],
        "following": features["userFollowingCount"],
        "biographyLength": features["userBiographyLength"],
        "mediaCount": features["userMediaCount"],
        "hasProfilePicture": features["userHasProfilPic"],
        "isPrivate": features["userIsPrivate"],
        **result
    }