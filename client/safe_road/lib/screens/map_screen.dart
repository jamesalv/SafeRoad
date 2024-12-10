import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safe_road/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:safe_road/models/road_defect.dart';

import 'package:safe_road/services/defect_service.dart';
import 'package:safe_road/widgets/defect_details_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? mapController;
  LatLng? selectedLocation;
  LatLng? currentPosition;
  String? selectedAddress;
  bool isLoading = false;
  String? analysisResult;
  List<RoadDefect> roadDefects = [];

  static const LatLng defaultPosition = LatLng(-6.973863, 110.390611);

  final TextEditingController radiusController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _getCurrentLocation();
    _subscribeToDefects();
  }

  @override
  bool get wantKeepAlive => true;

  // Circles for radius search
  Set<Circle> circles = {};

  // Separate sets for different types of markers
  Set<Marker> defectMarkers = {};
  Set<Marker> selectionMarkers = {};
  Set<Marker> get markers => {...defectMarkers, ...selectionMarkers};

  Future<void> _getCurrentLocation() async {
    try {
      setState(() async {
        currentPosition = await LocationService.getCurrentLocation();
      });

      // Move camera to current position if map controller is available
      if (mapController != null && currentPosition != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentPosition!,
              zoom: 14.0,
            ),
          ),
        );
      }

      // Log the current position
      debugPrint('Current Position: $currentPosition');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location Error: ${e.toString()}')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // If we already have the current position, move camera there
    if (currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPosition!,
            zoom: 14.0,
          ),
        ),
      );
    }
  }

  Future<void> _onMapTap(LatLng location) async {
    setState(() {
      selectedLocation = location;
      isLoading = true;
      // Update only the selection marker
      selectionMarkers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: location,
          // Blue color
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          zIndex: 2,
        ),
      };

      if (radiusController.text.isNotEmpty) {
        _updateCircle();
      }
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          selectedAddress =
              '${place.street}, ${place.locality}, ${place.country}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress = 'Address not found';
        isLoading = false;
      });
    }
  }

  void _updateCircle() {
    if (selectedLocation != null && radiusController.text.isNotEmpty) {
      double radius = double.parse(radiusController.text) * 1000;
      setState(() {
        circles = {
          Circle(
            circleId: const CircleId('searchRadius'),
            center: selectedLocation!,
            radius: radius,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        };
      });
    }
  }

  Future<void> _analyzeRoadDefects() async {
    if (selectedLocation == null ||
        radiusController.text.isEmpty ||
        pointsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields and select a location'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final newDefects = await DefectService.analyzeLocation(
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
        radius: double.parse(radiusController.text),
        numPoints: int.parse(pointsController.text),
      );

      // await DefectService.analyzeLocation(
      //   latitude: selectedLocation!.latitude,
      //   longitude: selectedLocation!.longitude,
      //   radius: double.parse(radiusController.text),
      //   numPoints: int.parse(pointsController.text),
      // );

      setState(() {
        final Set<String> existingTimestamps =
            roadDefects.map((d) => d.timestamp.toString()).toSet();

        roadDefects.addAll(newDefects.where((defect) =>
            !existingTimestamps.contains(defect.timestamp.toString())));
        _updateMarkers();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _subscribeToDefects() {
    DefectService.streamDefects().listen(
      (defects) {
        debugPrint('Received ${defects.length} defects at frontend wkwkwkwk');
        if (mounted) {
          setState(() {
            roadDefects = defects;
            _updateMarkers();
          });
        }
      },
      onError: (error) {
        debugPrint('Defect stream error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading defects: $error')),
          );
        }
      },
    );
  }

  void _updateMarkers() {
    if (!mounted) return;
    setState(() {
      defectMarkers = roadDefects.map((defect) {
        return Marker(
          markerId: MarkerId(defect.timestamp.toString()),
          position: defect.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _showDefectDetails(defect),
          // Add distinctive styling for defect markers
          zIndex: 1,
        );
      }).toSet();
    });

    debugPrint('Defect Markers updated: ${markers.length}');
  }

  void _showDefectDetails(RoadDefect defect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows custom height
      backgroundColor:
          Colors.transparent, // Makes the modal's top rounded corner visible
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize:
              0.6, // The initial height as a fraction of the screen
          minChildSize: 0.5, // Minimum height when the modal is collapsed
          maxChildSize: 0.95, // Maximum height when the modal is expanded
          builder: (context, scrollController) {
            return DefectDetailsSheet(
              defect: defect,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Road'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
              initialCameraPosition: CameraPosition(
                target: currentPosition ?? defaultPosition,
                zoom: 14.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: markers,
              circles: circles,
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (selectedLocation != null) ...[
                    Text(
                      'Selected Location:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}\n'
                      'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                    ),
                    const SizedBox(height: 8),
                    if (selectedAddress != null)
                      Text(
                        'Address: $selectedAddress',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                  ] else
                    Text(
                      'Tap on the map to select a location',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: radiusController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Radius (km)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _updateCircle(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Number of Points',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _analyzeRoadDefects,
                    child: const Text('Analyze Road Defects'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
