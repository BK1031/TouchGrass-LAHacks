import requests

def get_location_name(lat, lon, api_key):
    """Fetch location name using Google Maps Geocoding API."""
    base_url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {
        "latlng": f"{lat},{lon}",
        "key": api_key
    }
    response = requests.get(base_url, params=params)
    if response.status_code == 200:
        results = response.json()['results']
        if results:
            return results[0]['formatted_address']
        else:
            return "No location found for the given coordinates."
    else:
        return "Failed to fetch location data."

# Example usage
api_key = 'AIzaSyDnozzZIALIH0N1_1SASsOJjawiEhWS_Rc'  # Replace this with your actual Google Maps API key
latitude = 34.052235
longitude = -118.243683
location_name = get_location_name(latitude, longitude, api_key)
print("Location Name:", location_name)
