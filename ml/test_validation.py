from predict import detect_profile


print("========== VALIDATION TESTING ==========")


# ==========================================
# TEST 1 — VALID PROFILE
# ==========================================

try:

    result, confidence, level = detect_profile(
        userFollowerCount=500,
        userFollowingCount=450,
        userBiographyLength=50,
        userMediaCount=30,
        userHasProfilPic=1,
        userIsPrivate=0,
        usernameDigitCount=1,
        usernameLength=10
    )

    print("\nVALID PROFILE")
    print("PASS")
    print("Prediction:", result)
    print("Confidence:", round(confidence, 2), "%")
    print("Confidence Level:", level)

except ValueError as e:

    print("\nVALID PROFILE")
    print("FAIL")
    print("Error:", e)


# ==========================================
# TEST 2 — NEGATIVE FOLLOWERS
# ==========================================

try:

    detect_profile(
        userFollowerCount=-10,
        userFollowingCount=450,
        userBiographyLength=50,
        userMediaCount=30,
        userHasProfilPic=1,
        userIsPrivate=0,
        usernameDigitCount=1,
        usernameLength=10
    )

    print("\nNEGATIVE FOLLOWERS")
    print("FAIL - Invalid value was accepted")

except ValueError as e:

    print("\nNEGATIVE FOLLOWERS")
    print("PASS - Invalid value rejected")
    print("Error:", e)


# ==========================================
# TEST 3 — INVALID PROFILE PICTURE
# ==========================================

try:

    detect_profile(
        userFollowerCount=500,
        userFollowingCount=450,
        userBiographyLength=50,
        userMediaCount=30,
        userHasProfilPic=5,
        userIsPrivate=0,
        usernameDigitCount=1,
        usernameLength=10
    )

    print("\nINVALID PROFILE PICTURE")
    print("FAIL - Invalid value was accepted")

except ValueError as e:

    print("\nINVALID PROFILE PICTURE")
    print("PASS - Invalid value rejected")
    print("Error:", e)


# ==========================================
# TEST 4 — INVALID PRIVATE VALUE
# ==========================================

try:

    detect_profile(
        userFollowerCount=500,
        userFollowingCount=450,
        userBiographyLength=50,
        userMediaCount=30,
        userHasProfilPic=1,
        userIsPrivate=5,
        usernameDigitCount=1,
        usernameLength=10
    )

    print("\nINVALID PRIVATE VALUE")
    print("FAIL - Invalid value was accepted")

except ValueError as e:

    print("\nINVALID PRIVATE VALUE")
    print("PASS - Invalid value rejected")
    print("Error:", e)


# ==========================================
# FINAL RESULT
# ==========================================

print("\n==========================================")
print("VALIDATION TESTING COMPLETED")
print("==========================================")