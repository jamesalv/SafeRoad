import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sse_channel/sse_channel.dart';
import 'dart:convert';
import '../models/road_defect.dart';

class DefectService {
  static const String baseUrl = "http://localhost:8000";
  // static const String baseUrl = 'http://127.0.0.1:5000';

  static Stream<List<RoadDefect>> streamDefects() {
    final controller = StreamController<List<RoadDefect>>();
    final channel = SseChannel.connect(Uri.parse('$baseUrl/defects/stream'));
    channel.stream.listen((message) {
      final List<dynamic> data = json.decode(message);
      final defects = data.map((json) => RoadDefect.fromJson(json)).toList();
      debugPrint('Received ${defects.length} defects');
      controller.add(defects);
    });
    return controller.stream.handleError((error) {
      debugPrint('Error streaming defects: $error');
      return [];
    });
  }

  static Future<List<RoadDefect>> analyzeLocation({
    required double latitude,
    required double longitude,
    required double radius,
    required int numPoints,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'center_lat': latitude,
          'center_lng': longitude,
          'radius_km': radius,
          'num_points': numPoints,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RoadDefect.fromJson(json)).toList();
      } else {
        throw Exception('Failed to analyze road defects');
      }
    } catch (e) {
      debugPrint('Error analyzing location: $e');
      rethrow;
    }
  }
}

// Test 
void main(){
  DefectService.streamDefects();
  debugPrint('Test passed');
}
