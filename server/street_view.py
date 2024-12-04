from io import BytesIO
import math
import os
import random
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

def get_pano_id(lat, lng):
    """
    Get panorama id given the latitude and longitude
    * helps to make sure that the generated points are valid coordinates
    """
    metadata_url = f"{STREET_VIEW_URL}/metadata?location={lat},{lng}&key={API_KEY}"
    response = requests.get(metadata_url)
    data = response.json()
    return data.get("pano_id")

def generate_points_in_radius(center_lat, center_lon, radius_km, num_points):
    """
    Generate random points within a given radius from a center point
    """
    
    points = []
    i = 0
    while i < num_points:
        angle = math.radians(random.uniform(0, 360))
        distance = random.uniform(0, radius_km)

        lat_offset = distance / 111.32
        lon_offset = distance / (111.32 * math.cos(math.radians(center_lat)))

        new_lat = center_lat + (lat_offset * math.cos(angle))
        new_lon = center_lon + (lon_offset * math.sin(angle))
        
        pano_id = get_pano_id(new_lat, new_lon)
        if pano_id:
            points.append((new_lat, new_lon))
            i += 1

    return points


def capture_images_in_radius(center_lat, center_lon, radius_km, num_images):
    """
    Capture street view images within a given radius from a center point
    """

    points = generate_points_in_radius(center_lat, center_lon, radius_km, num_images)
    images = []

    for point in points:
        lat, lon = point
    
        # Get images in 4 directions
        for heading in range(0, 360, 90):
            image = get_street_view_image(lat, lon, heading)
            images.append(image)

    return images

# Test doang sich
# if __name__ == "__main__":
#     lat = -6.1753924
#     lng = 106.8271528
#     street_name = get_street_name(lat, lng)
#     print(street_name)
#     images = capture_images_in_radius(lat, lng, 0.5, 2)
#     for image in images:
#         image.show()
