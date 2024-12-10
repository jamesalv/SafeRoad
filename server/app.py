import base64
import io
import json
import queue
from PIL import Image
from flask import Flask, Response, request, jsonify
from flask_cors import CORS
from firebase import process_and_upload, fetch_defects, process_and_upload_reports
from detect import analyze_location, analyze_report
from street_view import capture_images_in_radius

# Create an app instance
app = Flask(__name__)

# Enable CORS
CORS(app, resources={r"/*": {"origins": "*", "supports_credentials": True}})

# Implement SSE for real time updates to the clients
# Queue to store clients subscribed to updates
clients = []

def notify_clients(data):
    """Notify all clients with new data"""
    for client in clients[:]:
        try:
            client.put(data)
            print("Notified client")
        except:
            clients.remove(client)

@app.route("/defects", methods=["GET"])
def get_defects():
    """
    Get all road defects from the database
    
    Returns:
        JSON response containing all defect records
    """
    try:
        defects = fetch_defects()
        return jsonify(defects)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/defects/stream")
def stream():
    """
    Create SSE stream for real-time updates
    """
    def generate():
        client_queue = queue.Queue()
        clients.append(client_queue)
        
        try:
            # Send initial data
            defects = fetch_defects()
            yield f"data: {json.dumps(defects)}\n\n"
            
            # Wait for updates
            while True:
                data = client_queue.get()
                yield f"data: {json.dumps(data)}\n\n"
        except GeneratorExit:
            clients.remove(client_queue)
    
    return Response(generate(), mimetype="text/event-stream")

@app.route("/analyze", methods=["POST"])
def analyze():
    """
    Analyze location on certain radius for defects

    Req params:
      center_lat (float): Latitude of the center point
      center_lng (float): Longitude of the center point
      radius_km (float): Radius in kilometers
      num_points (int): Number of points to generate

    Returns:
      JSON response containing the status of the request
    """

    args = request.json
    print(args)
    try:
        center_lat = float(args.get("center_lat"))
        center_lng = float(args.get("center_lng"))
        radius_km = float(args.get("radius_km"))
        num_points = int(args.get("num_points"))
        
        print("Collecting images... ", center_lat, center_lng, radius_km, num_points)
        images = capture_images_in_radius(center_lat, center_lng, radius_km, num_points)
        
        print("Analyzing images...")
        original_images, annotated_images, metadata = analyze_location(images, confidence_threshold=0.25)
        
        print("Processing and uploading to database...")
        result = process_and_upload(original_images, annotated_images, metadata)
        
        print("Notifying clients...")
        defects = fetch_defects()
        notify_clients(defects)
        
        # print(result)
        return jsonify(result)
    except Exception as e:
        print(f"Error occurred: {e}")
        return {"error": "Failed to analyze"}

@app.route("/report", methods=["POST"])
def report():
    """
    Report a defect on the road

    Form data params:
      description (str): Description of the defect
      image (file): Image file of the defect
      location (str): Location description

    Returns:
      JSON response containing the status of the request
    """
    try:
        print(request.form)
        print(request.files)
        # Check if required fields exist in form data
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
        
        image_file = request.files['image']
        description = request.form.get('description')
        location = request.form.get('location')

        if not all([description, location, image_file]):
            return jsonify({
                "error": "Missing required fields (description, image, or location)"
            }), 400

        # Convert uploaded file to PIL Image
        image = Image.open(image_file)

        # # Analyze the image for defects
        original_image, annotated_image, metadata = analyze_report([image], confidence_threshold=0.25)
        # Check if any defects were detected
        if len(metadata['defect_classes']) == 0:
            return jsonify({
                "message": "No defects detected in the image"
            }), 200

        # Add user-provided information to metadata
        metadata.update({
            'description': description,
            'location': location,
            'status': 'Unsolved',
            'reported_by': 'user' # Usernamenya disini nanti
        })

        # Upload to Firebase
        result = process_and_upload_reports(original_image, annotated_image, metadata)
        

        return jsonify({
            "message": "Report submitted successfully",
            "data": metadata
        }), 201

    except Exception as e:
        print(f"Error processing report: {str(e)}")
        return jsonify({
            "error": f"Failed to process report: {str(e)}"
        }), 500

# print(__name__)
if __name__ == "__main__":
    app.run(debug=False, port=8000, host='0.0.0.0')
