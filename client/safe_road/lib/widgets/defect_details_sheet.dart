import 'package:flutter/material.dart';
import 'package:safe_road/models/road_defect.dart';

class DefectDetailsSheet extends StatelessWidget {
  final RoadDefect defect;
  final ScrollController scrollController;

  const DefectDetailsSheet({
    super.key,
    required this.defect,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: SingleChildScrollView(
        controller: scrollController, // Attach the scroll controller
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  defect.annotatedImageUrl,
                  height: 300, // Larger height for better visibility
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                "Defect Details",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      defect.streetName,
                      style: const TextStyle(fontSize: 16.0, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orangeAccent),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      defect.defectClasses.join(', '),
                      style: const TextStyle(fontSize: 16.0, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blueAccent),
                  const SizedBox(width: 8.0),
                  Text(
                    "Detected: ${defect.timestamp}",
                    style: const TextStyle(fontSize: 14.0, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.cloud_upload, color: Colors.green),
                  const SizedBox(width: 8.0),
                  Text(
                    "Uploaded: ${defect.timestamp}",
                    style: const TextStyle(fontSize: 14.0, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
