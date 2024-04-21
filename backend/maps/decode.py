import requests
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore
from sklearn.cluster import DBSCAN
import numpy as np


cred = credentials.Certificate('../server/battleship-lahacks-firebase-adminsdk-j7rvt-06c45b06f4.json')
firebase_admin.initialize_app(cred)

db = firestore.client()



def DensityHaversineSpatialClustering(user_id):
    data = fetch_data(user_id)
    # Ensure there is data to process
    if not data:
        print("No location data available for user:", user_id)
        return
    
    # Convert to NumPy array and ensure it is 2D
    coords = np.array(data)
    
    # Check if coords is 2D and has more than one record to cluster
    if len(coords.shape) == 2 and coords.shape[0] > 1:
        dbscan = DBSCAN(eps=0.01, min_samples=5, metric='haversine')
        clusters = dbscan.fit_predict(np.radians(coords))  # Convert to radians
        clustered_data = coords[clusters != -1]  # Filter out noise points

        print("Number of clusters:", len(set(clusters)) - (1 if -1 in clusters else 0))
        print("Clustered coordinates:", clustered_data)
    else:
        print("Insufficient data to perform clustering.")

def fetch_data(user_id):
    data = []
    user_ref = db.collection('users').document(user_id)
    location_history_ref = user_ref.collection('location_history')
    location_history_docs = location_history_ref.stream()
    
    for location in location_history_docs:
        location_data = location.to_dict()
        lat = location_data.get('lat')
        lon = location_data.get('long')
        if lat is not None and lon is not None:
            data.append([float(lat), float(lon)])  # Convert to float in case they are not
            
    
    return data


  
  

def convert_to_location_names(data_array, api_key):
    location_names = []
    base_url = "https://maps.googleapis.com/maps/api/geocode/json"

    for data in data_array:
        params = {
            "latlng": f"{data['lat']},{data['lon']}",
            "key": api_key
        }
        response = requests.get(base_url, params=params)
        location_name = "Unknown location"
        if response.status_code == 200:
            results = response.json()['results']
            if results:
                location_name = results[0]['formatted_address']
        
        location_names.append({'location': location_name, 'time': data['time']})

    return location_names

# Example usage
# api_key = GMAPS_API_KEY_IOS  # Replace this with your actual Google Maps API key
# converted_data = convert_to_location_names(user_data, api_key)
# print(converted_data)


DensityHaversineSpatialClustering("A0vkafeOuHR2HWiJPYDzuA1PyjG3")

# genai.configure(api_key=GEMINI_API_KEY)

# # Set up the model
# generation_config = {
#   "temperature": 1,
#   "top_p": 0.95,
#   "top_k": 0,
#   "max_output_tokens": 8192,
# }

# safety_settings = [
#   {
#     "category": "HARM_CATEGORY_HARASSMENT",
#     "threshold": "BLOCK_MEDIUM_AND_ABOVE"
#   },
#   {
#     "category": "HARM_CATEGORY_HATE_SPEECH",
#     "threshold": "BLOCK_MEDIUM_AND_ABOVE"
#   },
#   {
#     "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
#     "threshold": "BLOCK_MEDIUM_AND_ABOVE"
#   },
#   {
#     "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
#     "threshold": "BLOCK_MEDIUM_AND_ABOVE"
#   },
# ]

# system_instruction = "\"Generate simple hints for an adventure/fitness exploration game where players guess each other's locations to encourage movement. Use the provided location data to craft hints that are intriguing yet not too revealing. The hints should encourage players to explore and think critically without giving away the exact location.\"\n\nEach hint should link the provided detail with the general vicinity or the ambiance of the location.\n\n\nOutput Expectations:\nYour language should be generally basic, not too cryptic or descriptive. \nThe model should output three separate hints corresponding to common locations, tailored to the details provided.\nEach hint should be no more than 1 sentence long, and should rhyme. The hints should be easy to understand and not too overly descriptive.  "

# model = genai.GenerativeModel(model_name="gemini-1.5-pro-latest",
#                               generation_config=generation_config,
#                               system_instruction=system_instruction,
#                               safety_settings=safety_settings)

# convo = model.start_chat(history=[
#   {
#     "role": "user",
#     "parts": ["Name:{\"location\": \"UCLA Dining Hall\", \"time\": \"2024-04-20T10:00:00Z\"},\n    {\"location\": \"Pauley Pavilion UCLA< LA\", \"time\": \"2024-04-20T12:00:00Z\"},\n    \n]"]
#   },
#   {
#     "role": "model",
#     "parts": ["### Hints for Ryan: \n\n***\n\n**Hint 1:**  Where students gather and stomachs rumble, lunchtime laughter, a place to fumble. \n\n**Hint 2:**  Home to Bruins with skills so bright, cheering crowds on a court of might."]
#   },
# ])

# convo.send_message("Name: Ryan\n {converted data} ")
# print(convo.last.text)

