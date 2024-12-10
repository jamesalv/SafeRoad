import firebase_admin
from firebase_admin import credentials, firestore, storage
from typing import List, Dict
from PIL import Image
import io
import uuid
from datetime import datetime

def init_firebase():
    """
    Initialize Firebase application with credentials and storage bucket.
    If the Firebase app is already initialized, it will not reinitialize.
    """
    cred = credentials.Certificate(
        "../secret/saferoad-7a1cb-firebase-adminsdk-z3dzs-dc11c42718.json"
    )
    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            cred, {"storageBucket": "saferoad-7a1cb.firebasestorage.app"}
        )

def get_storage_bucket():
    """
    Get the Firebase Storage bucket object.
    """
    bucket_name = "saferoad-7a1cb.firebasestorage.app"
    return storage.bucket(bucket_name)

def get_firestore_client():
    """
    Get the Firestore client.
    """
    return firestore.client()

def upload_image_to_storage(bucket, image: Image.Image, prefix: str) -> str:
    """
    Upload an image to Firebase Storage and return its public URL.
    
    Args:
        bucket: Firebase storage bucket
        image: PIL Image to upload
        prefix: Prefix for the image path (e.g., 'original' or 'annotated')
        
    Returns:
        Public URL of the uploaded image
    """
    # Convert PIL Image to bytes
    img_byte_arr = io.BytesIO()
    image.save(img_byte_arr, format='JPEG')
    img_byte_arr = img_byte_arr.getvalue()
    
    # Generate unique filename
    filename = f"{prefix}/{uuid.uuid4()}.jpg"
    
    # Upload to Firebase Storage
    blob = bucket.blob(filename)
    blob.upload_from_string(img_byte_arr, content_type='image/jpeg')
    
    # Make the blob publicly accessible and get URL
    blob.make_public()
    return blob.public_url

def process_and_upload(original_images: List[Image.Image], 
                      annotated_images: List[Image.Image], 
                      metadata: List[Dict]):
    """
    Process and upload images and metadata to Firebase.
    
    Args:
        original_images: List of original PIL images with defects
        annotated_images: List of annotated PIL images showing detections
        metadata: List of metadata dictionaries for the defect images
    """
    # Initialize Firebase
    init_firebase()
    bucket = get_storage_bucket()
    db = get_firestore_client()
    
    # Create a batch for Firestore operations
    batch = db.batch()
    
    # Collection reference
    defects_collection = db.collection('road_defects')
    
    # Results to return
    results = []
    
    # Process each set of images and metadata
    for idx, (original, annotated, meta) in enumerate(zip(original_images, annotated_images, metadata)):
        try:
            # Upload images to Storage
            original_url = upload_image_to_storage(bucket, original, 'original')
            annotated_url = upload_image_to_storage(bucket, annotated, 'annotated')
            
            # Add image URLs to metadata
            meta['images'] = {
                'original_url': original_url,
                'annotated_url': annotated_url
            }
            
            # Add additional metadata fields
            meta['upload_timestamp'] = datetime.now()
            meta['id'] = str(uuid.uuid4())
            
            # Add to Firestore batch
            doc_ref = defects_collection.document(meta['id'])
            batch.set(doc_ref, meta)
            
            print(f"Processed defect {idx + 1}: {meta['id']}")
            results.append(meta)
        except Exception as e:
            print(f"Error processing defect {idx + 1}: {str(e)}")
            continue
    
    # Commit the batch
    try:
        batch.commit()
        print(f"Successfully uploaded {len(metadata)} defect records to Firestore")
        return results
    except Exception as e:
        print(f"Error committing to Firestore: {str(e)}")
        return {"error": "Failed to upload defects to Firestore"}

def fetch_defects():
    """
    Retrieve all road defects from Firestore.
    
    Returns:
        List of dictionaries containing defect data
    """
    init_firebase()
    try:
        db = get_firestore_client()
        
        # Get all documents from the collection
        defects_ref = db.collection('road_defects')
        docs = defects_ref.stream()
        
        # Convert to list of dictionaries
        defects = []
        for doc in docs:
            data = doc.to_dict()
            # Convert timestamp to string for JSON serialization
            if 'upload_timestamp' in data:
                data['upload_timestamp'] = data['upload_timestamp'].strftime('%Y-%m-%d %H:%M:%S')
            defects.append(data)
            
        return defects
    except Exception as e:
        print(f"Error retrieving defects: {str(e)}")
        return []

def process_and_upload_reports(original_image, annotated_image, metadata):
    """
    Process and upload images and metadata to Firebase.
    
    Args:
        original_image: Original PIL image with defects
        annotated_image: Annotated PIL image showing detections
        metadata: Metadata dictionary for the defect image
    """
    # Initialize Firebase
    init_firebase()
    bucket = get_storage_bucket()
    db = get_firestore_client()
    
    # Create a batch for Firestore operations
    batch = db.batch()
    
    # Collection reference
    reports_collection = db.collection('defect_reports')
    
    try:
        # Upload images to Storage
        original_url = upload_image_to_storage(bucket, original_image[0], 'original')
        annotated_url = upload_image_to_storage(bucket, annotated_image[0], 'annotated')
        
        # Add image URLs to metadata
        metadata['images'] = {
            'original_url': original_url,
            'annotated_url': annotated_url
        }
        
        # Add additional metadata fields
        metadata['upload_timestamp'] = datetime.now()
        metadata['id'] = str(uuid.uuid4())
        
        # Add to Firestore batch
        doc_ref = reports_collection.document(metadata['id'])
        batch.set(doc_ref, metadata)
        
        print(f"Processed report: {metadata['id']}")
        batch.commit()
        return metadata
    except Exception as e:
        print(f"Error processing report: {str(e)}")
        return {"error": "Failed to upload report to Firestore"}
    

# if __name__ == "__main__":
#     # Example usage after running detection
#     from detect import analyze  # Import your detection module
#     from street_view import capture_images_in_radius
    
#     # Test coordinates
#     lat = -6.9736998
#     lng = 110.390662
    
#     # Capture and analyze images
#     image_results = capture_images_in_radius(lat, lng, 0.5, 2)
#     original_images, annotated_images, metadata = analyze(image_results)
    
#     # Upload to Firebase
#     if original_images:
#         process_and_upload(original_images, annotated_images, metadata)
#     else:
#         print("No defects detected to upload")