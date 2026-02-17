import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class IdUploadSection extends StatefulWidget {
  final Function(String?) onIdUploaded;
  final bool isRequired;
  final String? userId; // Optional: if not provided, will use 'temp_user_id'

  const IdUploadSection({
    super.key,
    required this.onIdUploaded,
    this.isRequired = true,
    this.userId,
  });

  @override
  State<IdUploadSection> createState() => _IdUploadSectionState();
}

class _IdUploadSectionState extends State<IdUploadSection> {
  File? _idImage;
  String? _uploadedIdUrl;
  bool _isUploading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _idImage = File(image.path);
          _errorMessage = null;
        });
        await _uploadId();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadId() async {
    if (_idImage == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final String fileName = path.basename(_idImage!.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String userId = widget.userId ?? 'temp_user_id';
      final String storagePath = 'model_verification/$userId/id_$timestamp$fileName';

      final Reference ref = FirebaseStorage.instance.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(_idImage!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadedIdUrl = downloadUrl;
        _isUploading = false;
      });

      widget.onIdUploaded(downloadUrl);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading ID: ${e.toString()}';
        _isUploading = false;
      });
      widget.onIdUploaded(null);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Identity Verification',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please upload a valid government-issued ID (Passport or Driver\'s License)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _idImage != null || _uploadedIdUrl != null
                    ? Colors.green
                    : Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: _isUploading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Uploading ID...'),
                      ],
                    ),
                  )
                : _idImage != null || _uploadedIdUrl != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _idImage != null
                                ? Image.file(
                                    _idImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : _uploadedIdUrl != null
                                    ? Image.network(
                                        _uploadedIdUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      )
                                    : const SizedBox(),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: TextButton(
                              onPressed: _showImageSourceDialog,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                              ),
                              child: const Text('Change'),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload ID',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Passport or Driver\'s License',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
            ),
          ),
        ],
        if (widget.isRequired && (_idImage == null && _uploadedIdUrl == null)) ...[
          const SizedBox(height: 8),
          Text(
            '* ID upload is required',
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
