import joblib
import pandas as pd

# Load the saved model
model = joblib.load("fake_profile_model.pkl")

print("Saved model loaded successfully!")

# Create one sample profile
# Test profile 1
profile_1 = pd.DataFrame([{
    "userFollowerCount": 1000,
    "userFollowingCount": 1,
    "userBiographyLength": 0,
    "userMediaCount": 0,
    "userHasProfilPic": 0,
    "userIsPrivate": 1,
    "usernameDigitCount": 0,
    "usernameLength": 10
}])

# Test profile 2
profile_2 = pd.DataFrame([{
    "userFollowerCount": 25,
    "userFollowingCount": 1937,
    "userBiographyLength": 0,
    "userMediaCount": 0,
    "userHasProfilPic": 1,
    "userIsPrivate": 1,
    "usernameDigitCount": 0,
    "usernameLength": 10
}])

prediction_1 = model.predict(profile_1)[0]
probability_1 = model.predict_proba(profile_1)[0]

prediction_2 = model.predict(profile_2)[0]
probability_2 = model.predict_proba(profile_2)[0]

print("\nPROFILE 1")
print("Prediction:", "FAKE" if prediction_1 == 1 else "REAL")
print("Real probability:", round(probability_1[0] * 100, 2), "%")
print("Fake probability:", round(probability_1[1] * 100, 2), "%")

print("\nPROFILE 2")
print("Prediction:", "FAKE" if prediction_2 == 1 else "REAL")
print("Real probability:", round(probability_2[0] * 100, 2), "%")
print("Fake probability:", round(probability_2[1] * 100, 2), "%")