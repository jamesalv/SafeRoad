import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/road_damage_report.dart';
import 'package:safe_road/utils/theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SafeRoadTheme.errorSnackBar('Error picking image: $e'),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SafeRoadTheme.errorSnackBar(
            'Please fill all required fields and add an image'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final report = RoadDamageReport(
        imagePath: _imageFile!.path,
        description: _descriptionController.text,
        location: _locationController.text,
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://34.30.253.136:5000/report"),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );

      request.fields.addAll({
        'description': report.description,
        'location': report.location,
      });

      var response = await request.send();

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          response.statusCode == 200
              ? SafeRoadTheme.errorSnackBar(
                  'No road damage detected. Please provide a clearer image.')
              : SafeRoadTheme.successSnackBar('Report submitted successfully!'),
        );
      } else {
        throw Exception('Failed to submit report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SafeRoadTheme.errorSnackBar('Error submitting report: $e'),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/SafeRoad Text Black.png',
                height: 25,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6), // Added spacing
            const Text(
              'REPORT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: SafeRoadTheme.background,
      ),
      body: _isLoading
          ? Center(child: SafeRoadTheme.loadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image preview section
                    if (_imageFile != null)
                      Container(
                        decoration: SafeRoadTheme.cardDecoration,
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              _imageFile!,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () =>
                                  setState(() => _imageFile = null),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload a photo or take a picture of the road damage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: SafeRoadTheme.primaryButton,
                            icon: const Icon(Icons.photo_library,
                                color: Colors.white),
                            label: const Text('Gallery'),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(
                            width: 16), // Add spacing between buttons
                        Expanded(
                          child: ElevatedButton.icon(
                            style: SafeRoadTheme.primaryButton,
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            label: const Text('Camera'),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: SafeRoadTheme.inputDecoration(
                        labelText: 'Location',
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter location'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: SafeRoadTheme.inputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe the road damage...',
                      ),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter description'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: SafeRoadTheme.primaryButton,
                      onPressed: _submitReport,
                      child: const Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
