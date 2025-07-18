import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:whatsapppp/common/repositories/common_blob_storage_repository.dart';

final mediaRepositoryProvider = Provider(
  (ref) => MediaRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    blobRepository: ref.watch(commonBlobStorageRepositoryProvider),
  ),
);

class MediaRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final CommonBlobStorageRepository blobRepository;

  MediaRepository({
    required this.auth,
    required this.firestore,
    required this.blobRepository,
  });

  // Image editing methods
  Future<File> cropImage({
    required File imageFile,
    required Rect cropRect,
    required Size originalSize,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) throw Exception('Failed to decode image');

      // Calculate crop coordinates
      final scaleX = image.width / originalSize.width;
      final scaleY = image.height / originalSize.height;

      final cropX = (cropRect.left * scaleX).round();
      final cropY = (cropRect.top * scaleY).round();
      final cropWidth = (cropRect.width * scaleX).round();
      final cropHeight = (cropRect.height * scaleY).round();

      final croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      final directory = await getTemporaryDirectory();
      final croppedFile = File(
          '${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

      return croppedFile;
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }

  Future<File> applyImageFilter({
    required File imageFile,
    required String filterType,
    double intensity = 1.0,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) throw Exception('Failed to decode image');

      img.Image filteredImage;

      switch (filterType) {
        case 'grayscale':
          filteredImage = img.grayscale(image);
          break;
        case 'sepia':
          filteredImage = img.sepia(image);
          break;
        case 'blur':
          filteredImage =
              img.gaussianBlur(image, radius: (intensity * 5).round());
          break;
        case 'brighten':
          filteredImage = img.adjustColor(image, gamma: 1.0, amount: intensity);
          break;
        case 'contrast':
          filteredImage = img.contrast(image, contrast: intensity * 1.5);
          break;
        case 'vintage':
          filteredImage = img.sepia(image);
          filteredImage = img.contrast(filteredImage, contrast: 1.2);
          filteredImage = img.adjustColor(filteredImage, brightness: -10);
          break;
        default:
          filteredImage = image;
      }

      final directory = await getTemporaryDirectory();
      final filteredFile = File(
          '${directory.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await filteredFile.writeAsBytes(img.encodeJpg(filteredImage));

      return filteredFile;
    } catch (e) {
      throw Exception('Failed to apply filter: $e');
    }
  }

  Future<File> addTextToImage({
    required File imageFile,
    required String text,
    required Offset position,
    required double fontSize,
    required Color textColor,
    required String fontFamily,
    bool isBold = false,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(image.width.toDouble(), image.height.toDouble());

      // Draw original image
      canvas.drawImage(image, Offset.zero, Paint());

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
            fontFamily: fontFamily,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, position);

      final picture = recorder.endRecording();
      final finalImage =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Failed to convert image to bytes');

      final directory = await getTemporaryDirectory();
      final textFile = File(
          '${directory.path}/text_${DateTime.now().millisecondsSinceEpoch}.png');

      await textFile.writeAsBytes(byteData.buffer.asUint8List());

      return textFile;
    } catch (e) {
      throw Exception('Failed to add text to image: $e');
    }
  }

  // Video editing methods
  Future<File> trimVideo({
    required File videoFile,
    required Duration startTime,
    required Duration endTime,
  }) async {
    try {
      // This is a placeholder implementation
      // In a real app, you would use a video processing library like ffmpeg_kit_flutter

      final directory = await getTemporaryDirectory();
      final trimmedFile = File(
          '${directory.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4');

      // For now, just copy the original file
      // In production, implement actual video trimming
      await videoFile.copy(trimmedFile.path);

      return trimmedFile;
    } catch (e) {
      throw Exception('Failed to trim video: $e');
    }
  }

  Future<File> addAudioToVideo({
    required File videoFile,
    required File audioFile,
    double volume = 1.0,
  }) async {
    try {
      // This is a placeholder implementation
      // In a real app, you would use a video processing library

      final directory = await getTemporaryDirectory();
      final outputFile = File(
          '${directory.path}/audio_video_${DateTime.now().millisecondsSinceEpoch}.mp4');

      // For now, just copy the original file
      await videoFile.copy(outputFile.path);

      return outputFile;
    } catch (e) {
      throw Exception('Failed to add audio to video: $e');
    }
  }

  Future<File> applyVideoFilter({
    required File videoFile,
    required String filterType,
  }) async {
    try {
      // This is a placeholder implementation
      // In a real app, you would use a video processing library

      final directory = await getTemporaryDirectory();
      final filteredFile = File(
          '${directory.path}/filtered_video_${DateTime.now().millisecondsSinceEpoch}.mp4');

      // For now, just copy the original file
      await videoFile.copy(filteredFile.path);

      return filteredFile;
    } catch (e) {
      throw Exception('Failed to apply video filter: $e');
    }
  }

  // UPDATED: Save edited media using blob storage with corrected Firebase path
  Future<String> saveEditedMedia({
    required File mediaFile,
    required String mediaType,
    required BuildContext context,
    String? originalFileName,
    String? projectId,
  }) async {
    try {
      // Generate a path for the blob storage
      final userId = auth.currentUser?.uid ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = originalFileName ?? 'edited_${mediaType}_$timestamp';
      final blobPath = 'media/$userId/edited_$mediaType/$fileName';

      // Store the file as a blob
      final blobId = await blobRepository.storeFileAsBlob(
        blobPath,
        mediaFile,
        context,
      );

      return blobId;
    } catch (e) {
      throw Exception('Failed to save media: $e');
    }
  }

  // UPDATED: Save edited image using blob storage with corrected Firebase path
  Future<String> saveEditedImageToBlob({
    required File editedImageFile,
    required String originalFileName,
    required BuildContext context,
    String? projectId,
  }) async {
    try {
      final userId = auth.currentUser?.uid ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = projectId != null
          ? 'project_${projectId}_${timestamp}.jpg'
          : 'edited_${originalFileName}_${timestamp}.jpg';

      final blobPath = 'media/$userId/edited_images/$fileName';

      // Store the image file as a blob
      final blobId = await blobRepository.storeFileAsBlob(
        blobPath,
        editedImageFile,
        context,
      );

      // IMPORTANT: Create Firestore document with the same ID as blobId
      await firestore.collection('edited_images').doc(blobId).set(
        {
          'userId': userId,
          'fileName': fileName,
          'blobPath': blobPath,
          'blobId': blobId,
          'storageType': 'blob',
          'mediaType': 'image',
          'originalFileName': originalFileName,
          'projectId': projectId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return blobId;
    } catch (e) {
      throw Exception('Failed to save edited image as blob: $e');
    }
  }

  Future<String> saveEditedVideoToBlob({
    required File editedVideoFile,
    required String originalFileName,
    required BuildContext context,
    String? projectId,
  }) async {
    try {
      final userId = auth.currentUser?.uid ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = projectId != null
          ? 'project_${projectId}_${timestamp}.mp4'
          : 'edited_${originalFileName}_${timestamp}.mp4';

      final blobPath = 'media/$userId/edited_videos/$fileName';

      // Store the video file as a blob
      final blobId = await blobRepository.storeFileAsBlob(
        blobPath,
        editedVideoFile,
        context,
      );

      await firestore.collection('edited_videos').doc(blobId).set(
        {
          'userId': userId,
          'fileName': fileName,
          'blobPath': blobPath,
          'blobId': blobId,
          'storageType': 'blob',
          'mediaType': 'video',
          'originalFileName': originalFileName,
          'projectId': projectId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return blobId;
    } catch (e) {
      throw Exception('Failed to save edited video as blob: $e');
    }
  }

  // UPDATED: Save editing session to top-level collection
  Future<void> saveEditingSession({
    required String sessionId,
    required String mediaType,
    required String originalMediaUrl,
    required Map<String, dynamic> editingData,
  }) async {
    try {
      // Create data map similar to how user data is saved
      Map<String, dynamic> sessionData = {
        'userId': auth.currentUser!.uid,
        'mediaType': mediaType,
        'originalMediaUrl': originalMediaUrl,
        'editingData': editingData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to 'editing_sessions' collection as top-level collection
      await firestore
          .collection('editing_sessions') // TOP-LEVEL COLLECTION
          .doc(sessionId)
          .set(sessionData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save editing session: $e');
    }
  }

  // Load editing session from Firestore
  Future<Map<String, dynamic>?> loadEditingSession(String sessionId) async {
    try {
      final doc =
          await firestore.collection('editing_sessions').doc(sessionId).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to load editing session: $e');
    }
  }

  // UPDATED: Get user's editing history from top-level collection
  Stream<List<Map<String, dynamic>>> getUserEditingHistory() {
    return firestore
        .collection('editing_sessions')
        .where('userId', isEqualTo: auth.currentUser!.uid)
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Get media by blob ID
  // Update getMediaFileFromBlob method to handle cross-user access:
  // UPDATED: Enhanced getMediaFileFromBlob method to handle voice-over images
  Future<File?> getMediaFileFromBlob({
    required String blobId,
    required String userId,
    String? fileName,
  }) async {
    try {
      print('MediaRepository: Getting media file for blobId: $blobId');

      // Try to get from edited_images first
      DocumentSnapshot doc =
          await firestore.collection('edited_images').doc(blobId).get();

      // If not found in images, try videos
      if (!doc.exists) {
        doc = await firestore.collection('edited_videos').doc(blobId).get();
      }

      if (doc.exists && doc.data() != null) {
        final data = doc.data()! as Map<String, dynamic>;
        print(
            'MediaRepository: Found Firestore document with data keys: ${data.keys.toList()}');

        // Check if this document contains base64 data directly
        if (data.containsKey('data')) {
          print('MediaRepository: Found base64 data in Firestore document');

          try {
            final base64Data = data['data'] as String;
            final imageBytes = base64Decode(base64Data);

            final directory = await getTemporaryDirectory();
            final tempFileName = fileName ??
                'blob_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final tempFile = File('${directory.path}/$tempFileName');

            await tempFile.writeAsBytes(imageBytes);

            print(
                'MediaRepository: Successfully created file from base64 data: ${tempFile.path}');
            return tempFile;
          } catch (e) {
            print('MediaRepository: Error decoding base64 data: $e');
          }
        }

        // NEW: Handle voice-over images specifically
        if (data.containsKey('hasVoiceOver') && data['hasVoiceOver'] == true) {
          print('MediaRepository: Handling voice-over image');

          // Check for image data stored separately for voice-over content
          if (data.containsKey('imageData')) {
            try {
              final base64Data = data['imageData'] as String;
              final imageBytes = base64Decode(base64Data);

              final directory = await getTemporaryDirectory();
              final tempFileName = fileName ??
                  'voiceover_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final tempFile = File('${directory.path}/$tempFileName');

              await tempFile.writeAsBytes(imageBytes);

              print(
                  'MediaRepository: Successfully created voice-over image file: ${tempFile.path}');
              return tempFile;
            } catch (e) {
              print(
                  'MediaRepository: Error decoding voice-over image data: $e');
            }
          }

          // If no separate imageData, try to use the original image path
          if (data.containsKey('originalImagePath')) {
            final originalPath = data['originalImagePath'] as String?;
            if (originalPath != null && File(originalPath).existsSync()) {
              print(
                  'MediaRepository: Using original image path for voice-over: $originalPath');
              return File(originalPath);
            }
          }
        }

        // NEW: Handle different media types for voice-over content
        final mediaType = data['mediaType'] as String?;
        if (mediaType == 'image_with_voiceover') {
          print('MediaRepository: Processing image_with_voiceover type');

          // Try to get the base image data
          if (data.containsKey('baseImageData')) {
            try {
              final base64Data = data['baseImageData'] as String;
              final imageBytes = base64Decode(base64Data);

              final directory = await getTemporaryDirectory();
              final tempFileName = fileName ??
                  'base_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final tempFile = File('${directory.path}/$tempFileName');

              await tempFile.writeAsBytes(imageBytes);

              print(
                  'MediaRepository: Successfully created base image file: ${tempFile.path}');
              return tempFile;
            } catch (e) {
              print('MediaRepository: Error decoding base image data: $e');
            }
          }
        }
      }

      // Fallback to blob repository method with enhanced error handling
      print('MediaRepository: Falling back to blob repository');
      try {
        final blobData = await blobRepository.getBlob(blobId, userId);

        if (blobData == null) {
          print('MediaRepository: No blob data found');

          // NEW: Try alternative user ID approach for cross-user access
          if (doc.exists && doc.data() != null) {
            final data = doc.data()! as Map<String, dynamic>;
            final originalUserId = data['userId'] as String?;

            if (originalUserId != null && originalUserId != userId) {
              print(
                  'MediaRepository: Trying with original userId: $originalUserId');
              final altBlobData =
                  await blobRepository.getBlob(blobId, originalUserId);

              if (altBlobData != null) {
                final directory = await getTemporaryDirectory();
                final tempFileName = fileName ??
                    'blob_file_${DateTime.now().millisecondsSinceEpoch}';
                final tempFile = File('${directory.path}/$tempFileName');

                await tempFile.writeAsBytes(altBlobData);
                print(
                    'MediaRepository: Created file from alternative user blob data: ${tempFile.path}');
                return tempFile;
              }
            }
          }

          return null;
        }

        final directory = await getTemporaryDirectory();
        final tempFileName =
            fileName ?? 'blob_file_${DateTime.now().millisecondsSinceEpoch}';
        final tempFile = File('${directory.path}/$tempFileName');

        await tempFile.writeAsBytes(blobData);
        print('MediaRepository: Created file from blob data: ${tempFile.path}');

        return tempFile;
      } catch (blobError) {
        print('MediaRepository: Blob repository error: $blobError');
        return null;
      }
    } catch (e) {
      print('MediaRepository: Failed to get media file from blob: $e');
      return null;
    }
  }

  // NEW: Enhanced method specifically for voice-over content
  Future<File?> getVoiceOverImageFromBlob({
    required String blobId,
    required String userId,
    String? fileName,
  }) async {
    try {
      print('MediaRepository: Getting voice-over image for blobId: $blobId');

      final doc = await firestore.collection('edited_images').doc(blobId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // Prioritize voice-over specific image data
        if (data.containsKey('imageData')) {
          try {
            final base64Data = data['imageData'] as String;
            final imageBytes = base64Decode(base64Data);

            final directory = await getTemporaryDirectory();
            final tempFileName = fileName ??
                'voiceover_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final tempFile = File('${directory.path}/$tempFileName');

            await tempFile.writeAsBytes(imageBytes);
            return tempFile;
          } catch (e) {
            print('MediaRepository: Error with voice-over image data: $e');
          }
        }
      }

      // Fallback to regular method
      return await getMediaFileFromBlob(
        blobId: blobId,
        userId: userId,
        fileName: fileName,
      );
    } catch (e) {
      print('MediaRepository: Failed to get voice-over image: $e');
      return null;
    }
  }

  // UPDATED: Enhanced save method for voice-over images
  Future<String> saveVoiceOverImageToBlob({
    required File imageFile,
    required String originalFileName,
    required String voiceOverPath,
    required BuildContext context,
    String? projectId,
  }) async {
    try {
      final userId = auth.currentUser?.uid ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = projectId != null
          ? 'voiceover_project_${projectId}_${timestamp}.jpg'
          : 'voiceover_${originalFileName}_${timestamp}.jpg';

      final blobPath = 'media/$userId/voiceover_images/$fileName';

      // Read image as base64 for direct storage
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Store the image file as a blob
      final blobId = await blobRepository.storeFileAsBlob(
        blobPath,
        imageFile,
        context,
      );

      // Create Firestore document with voice-over specific data
      await firestore.collection('edited_images').doc(blobId).set(
        {
          'userId': userId,
          'fileName': fileName,
          'blobPath': blobPath,
          'blobId': blobId,
          'storageType': 'blob',
          'mediaType': 'image_with_voiceover',
          'originalFileName': originalFileName,
          'projectId': projectId,
          'hasVoiceOver': true,
          'voiceOverPath': voiceOverPath,
          'imageData': base64Image, // Store base64 image for reliable access
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return blobId;
    } catch (e) {
      throw Exception('Failed to save voice-over image as blob: $e');
    }
  }

  // UPDATED: Get user's media files from top-level collection
  Stream<List<Map<String, dynamic>>> getUserMediaFiles() {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(<Map<String, dynamic>>[]);
    }

    return firestore
        .collection('edited_images')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'blobId': doc.id, // Ensure blobId is available
                    ...doc.data(),
                  })
              .toList()
            // Sort in Dart instead of Firestore to avoid index issues
            ..sort((a, b) {
              final aTime = a['createdAt'] as Timestamp?;
              final bTime = b['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // Descending order
            }),
        );
  }

  Stream<List<Map<String, dynamic>>> getUserMediaFilesByUserId(String userId) {
    return firestore
        .collection('edited_images')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['blobId'] = doc.id;
        data['id'] = doc.id;
        return data;
      }).toList()
        ..sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending order
        });
    });
  }

// Get video files for a specific user
  Stream<List<Map<String, dynamic>>> getUserVideoFilesByUserId(String userId) {
    return firestore
        .collection('edited_videos')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['blobId'] = doc.id;
        data['id'] = doc.id;
        return data;
      }).toList()
        ..sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending order
        });
    });
  }

  // UPDATED: Delete media file using document ID
  Future<bool> deleteMediaFile(String blobId, String userId) async {
    try {
      // Delete using blobId as document ID
      await firestore.collection('edited_images').doc(blobId).delete();

      // Delete blob data from blob storage
      // await blobRepository.deleteBlob(blobId, userId);

      return true;
    } catch (e) {
      print('Failed to delete media file: $e');
      return false;
    }
  }

  Future<bool> deleteVideoFile(String blobId, String userID) async {
    try {
      await firestore.collection('edited_videos').doc(blobId).delete();
      return true;
    } catch (e) {
      print('Failed to delete video file: $e');
      return false;
    }
  }

  // ADDED: Unified method to get media by type
  Stream<List<Map<String, dynamic>>> getMediaByType(String mediaType) {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(<Map<String, dynamic>>[]);
    }

    final collection = mediaType == 'image' ? 'edited_images' : 'edited_videos';

    return firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'blobId': doc.id, // Ensure blobId is available
                    ...doc.data(),
                  })
              .toList()
            // Sort in Dart to avoid Firestore index requirements
            ..sort((a, b) {
              final aTime = a['createdAt'] as Timestamp?;
              final bTime = b['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            }),
        );
  }
}
