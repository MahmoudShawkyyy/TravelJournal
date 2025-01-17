# Import necessary libraries
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from joblib import dump
import matplotlib.pyplot as plt
import seaborn as sns

# Load the dataset
dataset = pd.read_csv("tourism_data.csv")

# Check the dataset structure
print("Dataset Preview:")
print(dataset.head())
print("\nDataset Info:")
print(dataset.info())

# Handle missing values (if any)
dataset.fillna(method='ffill', inplace=True)

# Label encoding for categorical columns
categorical_columns = ['City', 'Continent', 'City Type', 'Tourism Type', 'Weather']
label_encoders = {}
for column in categorical_columns:
    le = LabelEncoder()
    dataset[column] = le.fit_transform(dataset[column])
    label_encoders[column] = le

# Define features (X) and target (y)
X = dataset[['Continent', 'City Type', 'Tourism Type', 'Weather', 'Accommodation Cost', 'Transportation Cost']].to_numpy()
y = dataset["City"].to_numpy()

# Normalize features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Split the dataset into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.35, random_state=7, shuffle=True)

# Initialize and train the Random Forest model
rf_model = RandomForestClassifier(n_estimators=100, random_state=7)

# Perform Cross-Validation
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=7)
cv_rf_scores = cross_val_score(rf_model, X_scaled, y, cv=cv, scoring='accuracy')

# Train the model on the training set
rf_model.fit(X_train, y_train)

# Predict on the test set
y_rf_pred = rf_model.predict(X_test)

# Evaluate accuracy
rf_accuracy = accuracy_score(y_test, y_rf_pred)

# Classification Report and Confusion Matrix
rf_classification_rep = classification_report(y_test, y_rf_pred)
rf_cf_matrix = confusion_matrix(y_test, y_rf_pred)

# Display results
print(f"\nCross-Validation Accuracy Scores (Random Forest): {cv_rf_scores}")
print(f"Average CV Accuracy (Random Forest): {np.mean(cv_rf_scores) * 100:.2f}%")
print(f"Accuracy on Test Set (Random Forest): {rf_accuracy * 100:.2f}%")
print("\nClassification Report (Random Forest):\n", rf_classification_rep)

# Plot Confusion Matrix
plt.figure(figsize=(10, 7))
sns.heatmap(rf_cf_matrix, annot=True, fmt='.0f', cmap='Blues')
plt.title('Confusion Matrix (Random Forest)')
plt.xlabel('Predicted')
plt.ylabel('Actual')
plt.show()

# Save the model, scaler, and label encoders
dump(rf_model, 'random_forest_model.pkl')
dump(scaler, 'scaler.pkl')
dump(label_encoders, 'label_encoders.pkl')

print("\nModel, scaler, and encoders saved in separate files.")
