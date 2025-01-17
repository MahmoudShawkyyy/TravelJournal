from flask import Flask, request, jsonify
from flask_cors import CORS
from joblib import load
import numpy as np
import os
# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS to allow requests from different origins

# Load individual components from separate files
model = load(os.path.join(os.getcwd(), 'random_forest_model.pkl'))
scaler = load(os.path.join(os.getcwd(), 'scaler.pkl'))
label_encoders = load(os.path.join(os.getcwd(), 'label_encoders.pkl'))

@app.route('/', methods=['GET'])
def home():
    """Test route to verify that the server is running."""
    return "Flask server is running. Use POST /predict to get predictions."

@app.route('/predict', methods=['POST'])
def predict_city():
    try:
        # Get JSON data from the request
        data = request.json

        # Validate inputs
        required_fields = [
            'Continent', 'City Type', 'Tourism Type', 'Weather',
            'Accommodation Cost', 'Transportation Cost'
        ]
        for field in required_fields:
            if field not in data:
                error_message = f"Missing field: {field}"
                print(error_message)
                return jsonify({'error': error_message}), 400

        # Extract and encode inputs
        try:
            continent = label_encoders['Continent'].transform([data['Continent']])[0]
            city_type = label_encoders['City Type'].transform([data['City Type']])[0]
            tourism_type = label_encoders['Tourism Type'].transform([data['Tourism Type']])[0]
            weather = label_encoders['Weather'].transform([data['Weather']])[0]
            accommodation_cost = int(data['Accommodation Cost'])
            transportation_cost = int(data['Transportation Cost'])
        except Exception as encoding_error:
            error_message = f"Encoding Error: {str(encoding_error)}"
            print(error_message)
            return jsonify({'error': error_message}), 400

        # Log transformed inputs
        print("Encoded Inputs:", continent, city_type, tourism_type, weather, accommodation_cost, transportation_cost)

        # Create feature array
        features = np.array([[continent, city_type, tourism_type, weather, accommodation_cost, transportation_cost]])

        # Scale the features
        features_scaled = scaler.transform(features)

        # Log scaled features
        print("Scaled Features:", features_scaled)

        # Predict using the model
        prediction_encoded = model.predict(features_scaled)[0]

        # Decode the prediction to the city name
        try:
            predicted_city = label_encoders['City'].inverse_transform([prediction_encoded])[0]
        except Exception as decoding_error:
            error_message = f"Decoding Error: {str(decoding_error)}"
            print(error_message)
            return jsonify({'error': error_message}), 500

        # Ensure the prediction is a Python int (not a numpy int)
        predicted_city = str(predicted_city)  # Ensures it's serializable as a string

        # Log the prediction
        print("Predicted City:", predicted_city)

        # Return the prediction as a JSON response
        return jsonify({'Predicted City': predicted_city})

    except Exception as e:
        # Log and return any other unexpected error
        print("Error during prediction:", str(e))
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # Listen on all network interfaces for testing
    app.run(host='0.0.0.0', port=5000, debug=True)
