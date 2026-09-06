import os
import joblib


# Get the folder where this file is located
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Model path
MODEL_PATH = os.path.join(BASE_DIR, "fake_profile_model.pkl")

# Load trained model
model = joblib.load(MODEL_PATH)


def detect_profile(
    userFollowerCount,
    userFollowingCount,
    userBiographyLength,
    userMediaCount,
    userHasProfilPic,
    userIsPrivate,
    usernameDigitCount,
    usernameLength
):

    # -----------------------------
    # INPUT VALIDATION
    # -----------------------------

    values = [
        userFollowerCount,
        userFollowingCount,
        userBiographyLength,
        userMediaCount,
        userHasProfilPic,
        userIsPrivate,
        usernameDigitCount,
        usernameLength
    ]

    if any(value < 0 for value in values):
        raise ValueError("Profile values cannot be negative.")

    if userHasProfilPic not in [0, 1]:
        raise ValueError("userHasProfilPic must be 0 or 1.")

    if userIsPrivate not in [0, 1]:
        raise ValueError("userIsPrivate must be 0 or 1.")

    # -----------------------------
    # MODEL INPUT
    # -----------------------------

    features = [[
        userFollowerCount,
        userFollowingCount,
        userBiographyLength,
        userMediaCount,
        userHasProfilPic,
        userIsPrivate,
        usernameDigitCount,
        usernameLength
    ]]

    # -----------------------------
    # AI PREDICTION
    # -----------------------------

    prediction = model.predict(features)[0]

    probabilities = model.predict_proba(features)[0]

    real_probability = probabilities[0]
    fake_probability = probabilities[1]

    if prediction == 1:
        result = "FAKE"
        confidence = fake_probability * 100
    else:
        result = "REAL"
        confidence = real_probability * 100

    # -----------------------------
    # CONFIDENCE LEVEL
    # -----------------------------

    if confidence >= 80:
        confidence_level = "High"
    elif confidence >= 60:
        confidence_level = "Moderate"
    else:
        confidence_level = "Low"

    # -----------------------------
    # RISK ANALYSIS
    # -----------------------------

    risk_factors = []

    # Following much higher than followers
    if userFollowerCount > 0:
        ratio = userFollowingCount / userFollowerCount

        if ratio >= 5:
            risk_factors.append(
                "Following count is much higher than follower count"
            )

    # Very low activity
    if userMediaCount == 0:
        risk_factors.append(
            "No media/posts detected"
        )
    elif userMediaCount <= 2:
        risk_factors.append(
            "Very low media activity"
        )

    # Biography
    if userBiographyLength == 0:
        risk_factors.append(
            "Biography is empty"
        )
    elif userBiographyLength <= 5:
        risk_factors.append(
            "Very short biography"
        )

    # Username digits
    if usernameDigitCount >= 4:
        risk_factors.append(
            "Username contains many digits"
        )

    # Profile picture
    if userHasProfilPic == 0:
        risk_factors.append(
            "No profile picture"
        )

    # Private account
    if userIsPrivate == 1:
        risk_factors.append(
            "Account is private"
        )

    # If no risk factors
    if len(risk_factors) == 0:
        risk_factors.append(
            "No major risk indicators detected"
        )

    # -----------------------------
    # RETURN RESULT
    # -----------------------------

    return result, round(confidence, 2), confidence_level, risk_factors