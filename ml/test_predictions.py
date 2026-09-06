from predict import detect_profile


# Test profiles
test_profiles = [

    {
        "name": "Suspicious Profile",
        "userFollowerCount": 25,
        "userFollowingCount": 1937,
        "userBiographyLength": 0,
        "userMediaCount": 0,
        "userHasProfilPic": 1,
        "userIsPrivate": 1,
        "usernameDigitCount": 0,
        "usernameLength": 10
    },

    {
        "name": "High Follower Profile",
        "userFollowerCount": 1000,
        "userFollowingCount": 1,
        "userBiographyLength": 0,
        "userMediaCount": 0,
        "userHasProfilPic": 0,
        "userIsPrivate": 1,
        "usernameDigitCount": 0,
        "usernameLength": 10
    },

    {
        "name": "Normal Profile",
        "userFollowerCount": 500,
        "userFollowingCount": 450,
        "userBiographyLength": 50,
        "userMediaCount": 30,
        "userHasProfilPic": 1,
        "userIsPrivate": 0,
        "usernameDigitCount": 1,
        "usernameLength": 10
    },

    {
        "name": "Low Activity Profile",
        "userFollowerCount": 10,
        "userFollowingCount": 500,
        "userBiographyLength": 0,
        "userMediaCount": 0,
        "userHasProfilPic": 0,
        "userIsPrivate": 1,
        "usernameDigitCount": 4,
        "usernameLength": 15
    },

    {
        "name": "Active Profile",
        "userFollowerCount": 800,
        "userFollowingCount": 700,
        "userBiographyLength": 80,
        "userMediaCount": 100,
        "userHasProfilPic": 1,
        "userIsPrivate": 0,
        "usernameDigitCount": 0,
        "usernameLength": 12
    }
]


print("========== PREDICTION TESTING ==========")

for profile in test_profiles:

    name = profile.pop("name")

    result, confidence, level = detect_profile(**profile)

    print("\nProfile:", name)
    print("Prediction:", result)
    print("Confidence:", round(confidence, 2), "%")
    print("Confidence Level:", level)