from ultralytics import YOLO
from street_view import capture_images_in_radius
from typing import List, Dict, Tuple
from datetime import datetime
from PIL import Image
import cv2
import json

model = YOLO("models/new/best.pt")

def detect(imgs, confidence_threshold=0.25) -> List[Dict]:
    """
    Detect road defects from images and return detection results
    
    Args:
        imgs: List of images to process
        confidence_threshold: Minimum confidence score for detection
        
    Returns:
        List of dictionaries containing detection results for each image
    """
    results = model(imgs)
    all_detections_metadata = []
    
    for result in results:
        image_detections = []
        for box in result.boxes:
            conf = float(box.conf[0])
            cls = int(box.cls[0])  # Extract the class index
            label = model.names[cls]  # Get the class name using the model's label map
            if conf > confidence_threshold:
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                image_detections.append({
                    "confidence": conf,
                    "class": label,
                    "bbox": [x1, y1, x2, y2]
                })
        all_detections_metadata.append(image_detections)
    
    return results, all_detections_metadata

def generate_defect_metadata(image_results: List[Dict], detections: List[Dict]) -> List[Dict]:
    """
    Generate metadata for images that contain road defects
    
    Args:
        image_results: List of dictionaries containing image information
        detections: List of detection results for each image
        
    Returns:
        List of metadata dictionaries for images with defects
    """
    metadata_list = []
    
    for img_data, img_detections in zip(image_results, detections):
        if img_detections:  # If there are any detections for this image
            metadata = {
                "timestamp": datetime.now().isoformat(),
                "location": {
                    "latitude": img_data["lat"],
                    "longitude": img_data["lon"],
                    "street_name": img_data["street_name"],
                    "heading": img_data["heading"]
                },
                "defect_classes": list(set(detection["class"] for detection in img_detections)),
                "defect_details": [
                    {
                        "confidence": detection["confidence"],
                        "class": detection["class"],
                        "bounding_box": {
                            "x1": detection["bbox"][0],
                            "y1": detection["bbox"][1],
                            "x2": detection["bbox"][2],
                            "y2": detection["bbox"][3]
                        }
                    }
                    for detection in img_detections
                ]
            }
            metadata_list.append(metadata)
    
    return metadata_list

def analyze_location(image_results: List[Dict], confidence_threshold: float = 0.25) -> Tuple[List[Image.Image], List[Image.Image], List[Dict]]:
    """
    Analyze street view images and return images with defects, their annotated versions, and metadata.
    
    Args:
        image_results: List of dictionaries containing image information and PIL images
        confidence_threshold: Minimum confidence score for detection
        
    Returns:
        Tuple containing:
        - List of original PIL images where defects were found
        - List of annotated PIL images showing the detected defects
        - List of metadata for images with defects
    """
    # Extract images for processing
    images = [result["img"] for result in image_results]
    
    # Run detection
    results, detections = detect(images, confidence_threshold)
    
    # Generate metadata
    metadata = generate_defect_metadata(image_results, detections)
    
    # Prepare return lists
    original_images = []
    annotated_images = []
    
    # Filter images with defects and create annotated versions
    for idx, (result, detection) in enumerate(zip(results, detections)):
        if detection:  # If defects were found
            original_images.append(images[idx])
            annotated_img = Image.fromarray(cv2.cvtColor(result.plot(), cv2.COLOR_BGR2RGB))
            annotated_images.append(annotated_img)
            
    
    return original_images, annotated_images, metadata

def generate_report_metadata(detections: List[List[Dict]]) -> Dict:
    """
    Generate metadata for a single defect report image
    
    Args:
        detections: List of detection results for the image (nested list)
        
    Returns:
        Metadata dictionary for the defect image
    """
    # Flatten detections
    flattened_detections = [d for sublist in detections for d in sublist]
    
    metadata = {
        "timestamp": datetime.now().isoformat(),
        "defect_classes": list(set(detection["class"] for detection in flattened_detections)),
        "defect_details": [
            {
                "confidence": detection["confidence"],
                "class": detection["class"],
                "bounding_box": {
                    "x1": detection["bbox"][0],
                    "y1": detection["bbox"][1],
                    "x2": detection["bbox"][2],
                    "y2": detection["bbox"][3]
                }
            }
            for detection in flattened_detections
        ]
    }
    
    return metadata

def analyze_report(defect_image: Image.Image, confidence_threshold: float = 0.25) -> Tuple[Image.Image, Image.Image, Dict]:
    """
    Analyze a single defect report image and return the annotated image and metadata.
    
    Args:
        defect_image: PIL Image of the defect report
        confidence_threshold: Minimum confidence score for detection
        
    Returns:
        Tuple containing:
        - Original PIL image
        - Annotated PIL image showing the detected defects
        - Metadata for the image
    """
    # Run detection
    results, detections = detect(defect_image, confidence_threshold)
    
    # Prepare return lists
    original_images = defect_image
    annotated_images = []
    metadata = generate_report_metadata(detections)
    
    # Filter images with defects and create annotated versions
    for idx, (result, detection) in enumerate(zip(results, detections)):
        if detection:  # If defects were found
            annotated_img = Image.fromarray(cv2.cvtColor(result.plot(), cv2.COLOR_BGR2RGB))
            annotated_images.append(annotated_img)
    
    return original_images, annotated_images, metadata

# Tester code
# if __name__ == "__main__":
#     # Test coordinates
#     lat = -6.1753924
#     lng = 106.8271528
    
#     # Capture images
#     image_results = capture_images_in_radius(lat, lng, 0.5, 2)
    
#     # Analyze images and get results
#     original_images, annotated_images, metadata = analyze(image_results)
    
#     # Print summary
#     print(f"Found defects in {len(original_images)} images")
    
#     # Save results
#     if metadata:
#         # Save metadata
#         with open('defect_metadata.json', 'w') as f:
#             json.dump(metadata, f, indent=2)
#         print("Metadata saved to defect_metadata.json")
        
#         # Save images
#         for idx, (orig, annot) in enumerate(zip(original_images, annotated_images)):
#             orig.save(f'defect_original_{idx}.jpg')
#             annot.save(f'defect_annotated_{idx}.jpg')
#             print(f"Saved image pair {idx + 1}")
