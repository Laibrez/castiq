import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class MediaUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryPublic _cloudinary = CloudinaryPublic('dhkugnymi', 'castiq', cache: false);

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
    required XFile videoFile,
    required Function(double) onProgress,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      onProgress(0.1); // Started
      
      CloudinaryResponse response;
      if (kIsWeb) {
        final bytes = await videoFile.readAsBytes();
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: 'video_$timestamp',
            folder: 'portfolios/$userId',
            resourceType: CloudinaryResourceType.Video,
          ),
        );
      } else {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            videoFile.path,
            identifier: 'video_$timestamp',
            folder: 'portfolios/$userId',
            resourceType: CloudinaryResourceType.Video,
          ),
        );
      }
      
      onProgress(1.0); // Completed

      final downloadUrl = response.secureUrl;

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
    required List<XFile> imageFiles,
    required Function(int completed, int total) onProgress,
  }) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        
        CloudinaryResponse response;
        if (kIsWeb) {
          final bytes = await imageFiles[i].readAsBytes();
          response = await _cloudinary.uploadFile(
            CloudinaryFile.fromBytesData(
              bytes,
              identifier: 'image_${timestamp}_$i',
              folder: 'portfolios/$userId',
            ),
          );
        } else {
          response = await _cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              imageFiles[i].path,
              identifier: 'image_${timestamp}_$i',
              folder: 'portfolios/$userId',
            ),
          );
        }
        
        downloadUrls.add(response.secureUrl);
        onProgress(i + 1, imageFiles.length);
      } catch (e) {
        print('Error uploading image $i: $e');
        // Continue with other images
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
    required XFile imageFile,
    required String folder,
    required Function(double) onProgress,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      onProgress(0.1); 

      CloudinaryResponse response;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: 'image_$timestamp',
            folder: '$folder/$userId',
          ),
        );
      } else {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile.path,
            identifier: 'image_$timestamp',
            folder: '$folder/$userId',
          ),
        );
      }

      onProgress(1.0);
      
      return response.secureUrl;
    } catch (e) {
      print('Error uploading single image: $e');
      return null;
    }
  }

  // Delete a media file from storage
  Future<bool> deleteMedia(String url) async {
    // Cloudinary unsigned deletion from client side safely is not typically supported 
    // without using a signature generated by a backend or using the Admin API (bad practice on client).
    // For now, we will return false or just silently fail as "not supported yet".
    // To properly support this, we would need a Cloud Function or backend endpoint.
    print('Deleting Cloudinary media from client is not securely supported without backend signature.');
    return false; 
  }
}
