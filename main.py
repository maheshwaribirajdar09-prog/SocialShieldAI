from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import sys
import os

# Add ML folder to Python path
ML_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "ml")
)

sys.path.append(ML_PATH)

from predict import detect_profile


app = FastAPI(
    title="SocialShieldAI API",
    description="AI-Based Fake Profile Detection API",
    version="1.0"
)


# -----------------------------
# CORS
# -----------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------
# PROFILE DATA
# -----------------------------

class Profile(BaseModel):

    userFollowerCount: int
    userFollowingCount: int
    userBiographyLength: int
    userMediaCount: int
    userHasProfilPic: int
    userIsPrivate: int
    usernameDigitCount: int
    usernameLength: int


# -----------------------------
# HOME
# -----------------------------

@app.get("/")
def home():

    return {
        "message": "SocialShieldAI API is running",
        "status": "OK"
    }


# -----------------------------
# PREDICTION
# -----------------------------

@app.post("/predict")
def predict(profile: Profile):

    try:

        result, confidence, confidence_level, risk_factors = detect_profile(
            profile.userFollowerCount,
            profile.userFollowingCount,
            profile.userBiographyLength,
            profile.userMediaCount,
            profile.userHasProfilPic,
            profile.userIsPrivate,
            profile.usernameDigitCount,
            profile.usernameLength
        )

        return {
            "prediction": result,
            "confidence": confidence,
            "confidence_level": confidence_level,
            "risk_factors": risk_factors
        }

    except ValueError as e:

        return {
            "error": str(e)
        }