import json
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    confusion_matrix,
    classification_report,
    roc_auc_score
)

# Load fake accounts
with open("../dataset/fakeAccountData.json", "r") as file:
    fake_data = json.load(file)

# Load real accounts
with open("../dataset/realAccountData.json", "r") as file:
    real_data = json.load(file)

# Combine both datasets
all_data = fake_data + real_data

# Convert JSON data into a DataFrame
df = pd.DataFrame(all_data)

print("Total accounts:", len(df))

print("\nDataset columns:")
print(df.columns.tolist())

print("\nFirst 5 rows:")
print(df.head())

# Separate features (X) and target (y)
X = df.drop("isFake", axis=1)
y = df["isFake"]

print("\nFeatures (X):")
print(X.columns.tolist())

print("\nTarget (y):")
print(y.value_counts())
# Split the data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42,
    stratify=y
)

print("\nTraining samples:", len(X_train))
print("Testing samples:", len(X_test))

print("\nTraining labels:")
print(y_train.value_counts())

print("\nTesting labels:")
print(y_test.value_counts())
# Create the Random Forest model
model = RandomForestClassifier(
    n_estimators=100,
    random_state=42
)

# Train the model
model.fit(X_train, y_train)

print("\nModel training completed successfully!")
# -----------------------------
# MODEL EVALUATION
# -----------------------------

# Make predictions
y_pred = model.predict(X_test)

# Probability of being fake
y_prob = model.predict_proba(X_test)[:, 1]

# Calculate evaluation metrics
accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred, zero_division=0)
recall = recall_score(y_test, y_pred, zero_division=0)
f1 = f1_score(y_test, y_pred, zero_division=0)
roc_auc = roc_auc_score(y_test, y_prob)

print("\n========== MODEL EVALUATION ==========")

print(f"Accuracy : {accuracy * 100:.2f}%")
print(f"Precision: {precision * 100:.2f}%")
print(f"Recall   : {recall * 100:.2f}%")
print(f"F1 Score : {f1 * 100:.2f}%")
print(f"ROC-AUC  : {roc_auc:.4f}")

print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))

print("\nClassification Report:")
print(classification_report(
    y_test,
    y_pred,
    target_names=["Real", "Fake"],
    zero_division=0
))
# Save the trained model
joblib.dump(model, "fake_profile_model.pkl")

print("\nModel saved successfully!")-+