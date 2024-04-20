import requests
import google.generativeai as genai

user_data = [
    {
        "lat": 34.0689,  # Latitude for UCLA
        "lon": -118.4452,  # Longitude for UCLA
        "time": "2024-04-20T10:00:00Z"  # Example timestamp
    },
    {
        "lat": 34.0522,  # Latitude for Los Angeles downtown
        "lon": -118.2437,  # Longitude for Los Angeles downtown
        "time": "2024-04-20T12:00:00Z"  # Another example timestamp
    },
    {
        "lat": 34.0076,  # Latitude for Venice Beach
        "lon": -118.4996,  # Longitude for Venice Beach
        "time": "2024-04-20T14:00:00Z"  # Another example timestamp
    },
    {
        "lat": 34.0522,  # Latitude for Los Angeles downtown
        "lon": -118.2437,  # Longitude for Los Angeles downtown
        "time": "2024-04-20T12:00:00Z"  # Another example timestamp
    },
    {
        "lat": 34.0076,  # Latitude for Venice Beach
        "lon": -118.4996,  # Longitude for Venice Beach
        "time": "2024-04-20T14:00:00Z"  # Another example timestamp
    },
    {
        "lat": 34.0522,  # Latitude for Los Angeles downtown
        "lon": -118.2437,  # Longitude for Los Angeles downtown
        "time": "2024-04-20T12:00:00Z"  # Another example timestamp
    },
    {
        "lat": 34.0076,  # Latitude for Venice Beach
        "lon": -118.4996,  # Longitude for Venice Beach
        "time": "2024-04-20T14:00:00Z"  # Another example timestamp
    }
]


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
api_key = 'AIzaSyDnozzZIALIH0N1_1SASsOJjawiEhWS_Rc'  # Replace this with your actual Google Maps API key
converted_data = convert_to_location_names(user_data, api_key)
print(converted_data)


"""
At the command line, only need to run once to install the package via pip:

$ pip install google-generativeai
"""


genai.configure(api_key='AIzaSyCX6hJZzwpu1cRddUug59k9gWZkvNPTscc')

# Set up the model
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

system_instruction = "\"Generate simple hints for an adventure/fitness exploration game where players guess each other's locations to encourage movement. Use the provided location data to craft hints that are intriguing yet not too revealing. The hints should encourage players to explore and think critically without giving away the exact location.\"\n\nEach hint should link the provided detail with the general vicinity or the ambiance of the location.\n\n\nOutput Expectations:\nYour language should be generally basic, not too cryptic or descriptive. \nThe model should output three separate hints corresponding to common locations, tailored to the details provided.\nEach hint should be no more than 1 sentence long, and should rhyme. The hints should be easy to understand and not too overly descriptive.  "

model = genai.GenerativeModel(model_name="gemini-1.5-pro-latest",
                              generation_config=generation_config,
                              system_instruction=system_instruction,
                              safety_settings=safety_settings)

convo = model.start_chat(history=[
  {
    "role": "user",
    "parts": ["Name: Ryan\n[\n    {\"location\": \"UCLA Dining Hall\", \"time\": \"2024-04-20T10:00:00Z\"},\n    {\"location\": \"Pauley Pavilion UCLA< LA\", \"time\": \"2024-04-20T12:00:00Z\"},\n    \n]"]
  },
  {
    "role": "model",
    "parts": ["### Hints for Ryan: \n\n***\n\n**Hint 1:**  Where students gather and stomachs rumble, lunchtime laughter, a place to fumble. \n\n**Hint 2:**  Home to Bruins with skills so bright, cheering crowds on a court of might."]
  },
])

convo.send_message("Name: Ryan\n {converted data} ")
print(convo.last.text)