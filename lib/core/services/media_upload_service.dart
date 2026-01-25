import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class MediaUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick a video from gallery or camera
  Future<XFile?> pickVideo({bool fromCamera = false}) async {
    return await _picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
  }

  // Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages() async {
    return await _picker.pickMultiImage(imageQuality: 85);
  }

  // Pick a single image
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    return await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
  }

  // Upload video with progress callback
  Future<String?> uploadVideo({
    required String userId,
    required File videoFile,
    required Function(double) onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('portfolios/$userId/video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      final uploadTask = ref.putFile(videoFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'portfolioVideo': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  // Upload multiple images with progress callback
  Future<List<String>> uploadMultipleImages({
    required String userId,
    required List<File> imageFiles,
    required Function(int completed, int total) onProgress,
  }) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final ref = _storage.ref().child('portfolios/$userId/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        final uploadTask = ref.putFile(imageFiles[i]);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        onProgress(i + 1, imageFiles.length);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }

    // Update Firestore with all image URLs
    if (downloadUrls.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update({
        'portfolioImages': FieldValue.arrayUnion(downloadUrls),
      });
    }

    return downloadUrls;
  }

  // Upload a single image (for profile photo, etc.)
  Future<String?> uploadSingleImage({
    required String userId,
    required File imageFile,
    required String folder,
    required Function(double) onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('$folder/$userId/image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(imageFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete a media file from storage
  Future<bool> deleteMedia(String url) async {
    try {
      await _storage.refFromURL(url).delete();
      return true;
    } catch (e) {
      print('Error deleting media: $e');
      return false;
    }
  }
}
