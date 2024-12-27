import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'defect_detail.dart';

class RoadDefect {
  final DateTime timestamp;
  final LatLng location;
  final String streetName;
  final double heading;
  final List<String> defectClasses;
  final List<DefectDetail> defectDetails;
  final String originalImageUrl;
  final String annotatedImageUrl;

  RoadDefect({
    required this.timestamp,
    required this.location,
    required this.streetName,
    required this.heading,
    required this.defectClasses,
    required this.defectDetails,
    required this.originalImageUrl,
    required this.annotatedImageUrl,
  });

  factory RoadDefect.fromJson(Map<String, dynamic> json) {
    return RoadDefect(
      timestamp: DateTime.parse(json['timestamp']),
      location: LatLng(
        json['location']['latitude'],
        json['location']['longitude'],
      ),
      streetName: json['location']['street_name'],
      heading: json['location']['heading'].toDouble(),
      defectClasses: List<String>.from(json['defect_classes']),
      defectDetails: (json['defect_details'] as List)
          .map((detail) => DefectDetail.fromJson(detail))
          .toList(),
      originalImageUrl: json['images']['original_url'],
      annotatedImageUrl: json['images']['annotated_url'],
    );
  }
}