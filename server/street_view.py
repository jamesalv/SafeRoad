from io import BytesIO
import os
from dotenv import load_dotenv
import requests
from PIL import Image

# Google API's
STREET_VIEW_URL = "https://maps.googleapis.com/maps/api/streetview"
GEOCODING_URL = "https://maps.googleapis.com/maps/api/geocode/json"

# API Key
load_dotenv()
API_KEY = os.getenv("GOOGLE_API_KEY")

def get_street_name(lat, lng):
    """
    Get the street name of the given latitude and longitude
    """

    # Get the address from the given latitude and longitude
    params = {"latlng": f"{lat},{lng}", "key": API_KEY}
    response = requests.get(GEOCODING_URL, params=params)
    data = response.json()

    if data["status"] == "OK":
        for result in data["results"]:
            for component in result["address_components"]:
                if "route" in component["types"]:
                    return component["long_name"]
    return "Unknown Street"


def get_street_view_image(lat, lng, heading):
    """
    Get the street view image of the given latitude, longitude, and heading
    """

    params = {
        "size": "640x640",
        "location": f"{lat},{lng}",
        "heading": heading,
        "fov": 90,
        "pitch": -30,
        "key": API_KEY,
    }
    
    response = requests.get(STREET_VIEW_URL, params=params)
    image = Image.open(BytesIO(response.content))
    return image


# Test doang sich
# if __name__ == "__main__":
#     lat = -6.1753924
#     lng = 106.8271528
#     street_name = get_street_name(lat, lng)
#     print(street_name)
#     img = get_street_view_image(lat, lng, 0)
#     img.show()
