import requests
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore
from sklearn.cluster import DBSCAN
import numpy as np
import os


if not firebase_admin._apps:
    cred = credentials.Certificate('../server/battleship-lahacks-firebase-adminsdk-j7rvt-06c45b06f4.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()


def fetch_data(user_id: str) -> list:
    data = []
    user_ref = db.collection('users').document(user_id)
    location_history_ref = user_ref.collection('location_history')
    
    try:
        location_history_docs = location_history_ref.stream()
        for location in location_history_docs:
            location_data = location.to_dict()
            lat = location_data.get('lat')
            lon = location_data.get('long')
            if lat is not None and lon is not None:
                data.append([float(lat), float(lon)])
    except Exception as e:
        print(f"An error occurred: {e}")
    return data

def DensityHaversineSpatialClustering(user_id):
    data = fetch_data(user_id)
    if data:
        coords = np.array(data)

        if coords.ndim == 2 and len(coords) > 1:
            # Perform DBSCAN
            dbscan = DBSCAN(eps=0.001, min_samples=5, metric='haversine')
            clusters = dbscan.fit_predict(np.radians(coords))  # Convert to radians for haversine metric

            # Calculate and print cluster centers
            unique_clusters = set(clusters) - {-1}  # Exclude noise points
            print("Number of clusters:", len(unique_clusters))
            
            # Iterate through each cluster to calculate centroids
            clustered_data = []
            for cluster_id in unique_clusters:
                # Indices of points in the current cluster
                indices = clusters == cluster_id
                # Calculate the centroid for the current cluster
                centroid = coords[indices].mean(axis=0)
                print(f"Cluster {cluster_id} center at: {centroid}")
                clustered_data.append(centroid)
            return clustered_data
             
        else:
            print("Insufficient data to perform clustering.")
    else:
        print(f"No data available for user {user_id}")
    return None

  
  


def convert_to_location_names(data_array, api_key):
    location_names = []
    base_url = "https://maps.googleapis.com/maps/api/geocode/json"

    for coords in data_array:
        # Ensure coords are floats and unpack the latitude and longitude
        lat, lon = map(float, coords)
        params = {
            'latlng': f"{lat},{lon}",
            'key': api_key
        }
        response = requests.get(base_url, params=params)

        # Check if the request was successful
        if response.status_code == 200:
            result = response.json()

            # Extract the formatted address if results are available
            if result['results']:
                address = result['results'][0]['formatted_address']
                location_names.append(address)
            else:
                location_names.append("No address found for this location.")
        else:
            location_names.append("Failed to retrieve the address.")

    return location_names
  
  

# Example usage



def get_user_hint(user_id, username):
    user_data = DensityHaversineSpatialClustering(user_id)
    api_key = os.getenv('GMAPS_API_KEY_IOS')
    converted_data = convert_to_location_names(user_data, api_key)
    # print(converted_data)
    key = os.getenv('GEMINI_API_KEY')
    genai.configure(api_key=key)
    generation_config = {
      "temperature": 1,
      "top_p": 0.95,
      "top_k": 0,
      "max_output_tokens": 8192,
    }
    safety_settings = [
      {
        "category": "HARM_CATEGORY_HARASSMENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_HATE_SPEECH",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
    ]
    # system_instruction = "\" "
    model = genai.GenerativeModel(model_name="gemini-pro",
                                  generation_config=generation_config,
                                  # system_instruction=system_instruction,
                                  safety_settings=safety_settings)
    convo = model.start_chat(history=[
    ])
    convo.send_message("Name: {username}\n {converted_data} Generate simple hints for an adventure/fitness exploration game where players guess each other's locations to encourage movement. Use the provided location data to craft hints that are intriguing yet not too revealing. The hints should encourage players to explore and think critically without giving away the exact location.\"\n\nEach hint should link the provided detail with the general vicinity or the ambiance of the location.\n\n\nOutput Expectations:\nYour language should be generally basic, not too cryptic or descriptive. \nThe model should output three separate hints corresponding to common locations, tailored to the details provided.\nEach hint should be no more than 1 sentence long, and should rhyme. The hints should be easy to understand and not too overly descriptive. The hints should total be no more than 2 sentences ")
    
    return convo.last.text

    
def get_user_summary(user_id):
    user_data = DensityHaversineSpatialClustering(user_id)
    api_key = os.getenv('GMAPS_API_KEY_IOS')
    converted_data = convert_to_location_names(user_data, api_key)
    key = os.getenv('GEMINI_API_KEY')
    genai.configure(api_key=key)
    generation_config = {
      "temperature": 1,
      "top_p": 0.95,
      "top_k": 0,
      "max_output_tokens": 8192,
    }
    safety_settings = [
      {
        "category": "HARM_CATEGORY_HARASSMENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_HATE_SPEECH",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE"
      },
    ]
    # system_instruction = ""
    model = genai.GenerativeModel(model_name="gemini-pro",
                                  generation_config=generation_config,
                                  # system_instruction=system_instruction,
                                  safety_settings=safety_settings)
    convo = model.start_chat(history=[
    ])
    convo.send_message("Name: {username}\n {converted_data} Generate a summary of the user's location data. The summary should be concise and informative, providing an overview of the user's visited locations. Use the provided location data to generate a summary that highlights the diversity and distribution of the locations. The summary should be engaging and easy to understand, capturing the essence of the user's travel experiences. The summary should be no more than 3 sentences long and should provide a clear picture of the user's movement patterns. It should also predict info regarding their activity and health")
    
    return convo.last.text

print(get_user_hint('BsKq1P2qSERKpRHkOLbsDe9ygwr1', 'Ryan'))

print(get_user_summary('BsKq1P2qSERKpRHkOLbsDe9ygwr1'))
