import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

// this is a repository for handling blob storage in a Flutter app
// using Firebase Firestore and local storage
// improved version of repository with better memory management and compression
final commonBlobStorageRepositoryProvider = Provider(
  (ref) => CommonBlobStorageRepository(
    firestore: FirebaseFirestore.instance,
  ),
);

class CommonBlobStorageRepository {
  final FirebaseFirestore firestore;

  CommonBlobStorageRepository({
    required this.firestore,
  });

  // More aggressive file size limits for free tier
  static const int maxImageSize = 300 * 1024; // 300KB for images
  static const int maxVideoSize = 2 * 1024 * 1024; // 2MB for videos
  static const int maxAudioSize = 500 * 1024; // 500KB for audio
  static const int firestoreDocLimit = 500 * 1024; // 500KB for Firestore docs

  // Store file as BLOB with improved compression and error handling
  Future<String> storeFileAsBlob(
    String path,
    File file,
    BuildContext? context,
  ) async {
    try {
      print('BlobRepository: Processing file: ${file.path}');

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final fileSize = await file.length();
      final contentType = _getContentType(file.path);

      print('BlobRepository: File size: $fileSize bytes, Type: $contentType');

      // Generate a unique ID for this file
      final fileId = const Uuid().v1();
      final userId = path.split('/')[2]; // Extract user ID from path

      // Handle based on file type with size checks
      if (contentType.startsWith('video/')) {
        if (fileSize > maxVideoSize) {
          throw Exception(
              'Video file too large (max ${(maxVideoSize / (1024 * 1024)).toStringAsFixed(1)}MB)');
        }
        return await _storeVideoAsBlob(path, file, fileId, userId, context);
      } else if (contentType.startsWith('audio/')) {
        if (fileSize > maxAudioSize) {
          throw Exception(
              'Audio file too large (max ${(maxAudioSize / 1024).toStringAsFixed(0)}KB)');
        }
        return await _storeAudioAsBlob(path, file, fileId, userId, context);
      } else if (contentType.startsWith('image/')) {
        return await _storeImageAsBlob(path, file, fileId, userId, context);
      } else {
        throw Exception('Unsupported file type: $contentType');
      }
    } catch (e) {
      print('BlobRepository: Error storing file: $e');
      if (context != null) {
        showSnackBar(context, 'Error: $e');
      }
      rethrow;
    }
  }

  // Improved image storage with better compression
  Future<String> _storeImageAsBlob(
    String path,
    File file,
    String fileId,
    String userId,
    BuildContext? context,
  ) async {
    try {
      print('BlobRepository: Processing image file');

      // Read and compress image
      Uint8List imageBytes = await file.readAsBytes();
      final originalSize = imageBytes.length;

      // If image is too large, compress it
      if (originalSize > maxImageSize) {
        print('BlobRepository: Compressing image from $originalSize bytes');

        // Use Flutter's image compression
        final codec = await instantiateImageCodec(
          imageBytes,
          targetWidth: 800, // Max width
          targetHeight: 600, // Max height
        );
        final frame = await codec.getNextFrame();

        // Convert back to bytes with JPEG compression
        final byteData =
            await frame.image.toByteData(format: ImageByteFormat.png);
        if (byteData != null) {
          imageBytes = byteData.buffer.asUint8List();
        }

        // If still too large, reduce quality further
        if (imageBytes.length > maxImageSize) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${fileId}_temp.jpg');
          await tempFile.writeAsBytes(imageBytes);

          // Use FFmpeg for more aggressive compression
          final compressedPath = '${tempDir.path}/${fileId}_compressed.jpg';
          final session = await FFmpegKit.execute(
              '-i ${tempFile.path} -q:v 8 -vf "scale=\'min(640,iw)\':\'min(480,ih)\':force_original_aspect_ratio=decrease" $compressedPath');

          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            final compressedFile = File(compressedPath);
            if (await compressedFile.exists()) {
              imageBytes = await compressedFile.readAsBytes();
              await compressedFile.delete();
            }
          }
          await tempFile.delete();
        }
      }

      final finalSize = imageBytes.length;
      print('BlobRepository: Final image size: $finalSize bytes');

      if (finalSize > firestoreDocLimit) {
        throw Exception('Image still too large after compression');
      }

      // Store in Firestore
      final base64Image = base64Encode(imageBytes);
      await firestore
          .collection('users')
          .doc(userId)
          .collection('media')
          .doc(fileId)
          .set({
        'data': base64Image,
        'path': path,
        'contentType': 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
        'size': finalSize,
        'originalSize': originalSize,
        'storageType': 'firestore_blob',
      });

      print('BlobRepository: Image stored with ID: $fileId');
      return fileId;
    } catch (e) {
      print('BlobRepository: Error storing image: $e');
      rethrow;
    }
  }

  // Improved video storage with better error handling
  Future<String> _storeVideoAsBlob(
    String path,
    File file,
    String fileId,
    String userId,
    BuildContext? context,
  ) async {
    try {
      print('BlobRepository: Processing video file');

      // Get app directories
      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Compress video more aggressively for smaller size
      print('BlobRepository: Compressing video...');
      final compressedVideoPath = '${videoDir.path}/${fileId}_compressed.mp4';

      // More aggressive compression settings
      final session = await FFmpegKit.execute(
          '-i ${file.path} -c:v libx264 -crf 32 -preset ultrafast -c:a aac -b:a 32k -vf "scale=\'min(480,iw)\':\'min(360,ih)\':force_original_aspect_ratio=decrease" -movflags +faststart $compressedVideoPath');

      final returnCode = await session.getReturnCode();

      File finalVideoFile;
      if (ReturnCode.isSuccess(returnCode)) {
        finalVideoFile = File(compressedVideoPath);
        final compressedSize = await finalVideoFile.length();
        print('BlobRepository: Video compressed to $compressedSize bytes');

        // If still too large, try even more aggressive compression
        if (compressedSize > maxVideoSize) {
          final ultraCompressedPath = '${videoDir.path}/${fileId}_ultra.mp4';
          final ultraSession = await FFmpegKit.execute(
              '-i $compressedVideoPath -c:v libx264 -crf 35 -preset ultrafast -c:a aac -b:a 24k -vf "scale=320:240" -r 15 -movflags +faststart $ultraCompressedPath');

          final ultraReturnCode = await ultraSession.getReturnCode();
          if (ReturnCode.isSuccess(ultraReturnCode)) {
            await finalVideoFile.delete();
            finalVideoFile = File(ultraCompressedPath);
            print('BlobRepository: Ultra compression successful');
          }
        }
      } else {
        print('BlobRepository: Video compression failed, using original');
        finalVideoFile = file;
      }

      // Check final size
      final finalSize = await finalVideoFile.length();
      if (finalSize > maxVideoSize) {
        if (finalVideoFile.path != file.path) {
          await finalVideoFile.delete();
        }
        throw Exception(
          'Video too large even after compression (max ${(maxVideoSize / (1024 * 1024)).toStringAsFixed(1)}MB)',
        );
      }

      // Generate thumbnail with error handling
      Uint8List? thumbnailBytes;
      try {
        thumbnailBytes = await VideoThumbnail.thumbnailData(
          video: finalVideoFile.path,
          imageFormat: ImageFormat.JPEG,
          quality: 30, // Lower quality for smaller size
          maxWidth: 200, // Smaller thumbnail
          maxHeight: 150,
        );
      } catch (e) {
        print('BlobRepository: Thumbnail generation failed: $e');
        // Create a placeholder thumbnail
        thumbnailBytes = Uint8List.fromList([]);
      }

      String? base64Thumbnail;
      if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
        base64Thumbnail = base64Encode(thumbnailBytes);
      }

      // Extract basic video metadata safely
      Map<String, dynamic> videoMetadata = {
        'fileSize': finalSize,
        'isCompressed': finalVideoFile.path != file.path,
      };

      try {
        final videoInfo = await VideoCompress.getMediaInfo(finalVideoFile.path);
        videoMetadata.addAll({
          'duration': videoInfo.duration ?? 0,
          'width': videoInfo.width ?? 0,
          'height': videoInfo.height ?? 0,
          'orientation': videoInfo.orientation ?? 0,
        });
      } catch (e) {
        print('BlobRepository: Error getting video metadata: $e');
      }

      // Store video locally
      final localPath = '${videoDir.path}/$fileId.mp4';
      if (finalVideoFile.path != localPath) {
        await finalVideoFile.copy(localPath);
        if (finalVideoFile.path != file.path) {
          await finalVideoFile.delete();
        }
      }

      // Store metadata in Firestore
      final documentData = <String, dynamic>{
        'metadata': videoMetadata,
        'path': path,
        'contentType': 'video/mp4',
        'createdAt': FieldValue.serverTimestamp(),
        'isLocalStorage': true,
        'localPath': localPath,
        'storageType': 'local_video',
      };

      if (base64Thumbnail != null) {
        documentData['thumbnail'] = base64Thumbnail;
      }

      await firestore
          .collection('users')
          .doc(userId)
          .collection('media')
          .doc(fileId)
          .set(documentData);

      print('BlobRepository: Video stored with ID: $fileId');
      return fileId;
    } catch (e) {
      print('BlobRepository: Error storing video: $e');
      if (context != null) {
        showSnackBar(context, 'Error storing video: $e');
      }
      rethrow;
    }
  }

  // Improved audio storage with better compression
  Future<String> _storeAudioAsBlob(
    String path,
    File file,
    String fileId,
    String userId,
    BuildContext? context,
  ) async {
    try {
      print('BlobRepository: Processing audio file');

      // Get app directories
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Extract audio duration safely
      int durationInSeconds = 0;
      try {
        final durationSession =
            await FFmpegKit.execute('-i ${file.path} -f null -');
        final log = await durationSession.getOutput();

        RegExp durationRegex =
            RegExp(r"Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})");
        Match? match = durationRegex.firstMatch(log ?? "");

        if (match != null) {
          int hours = int.parse(match.group(1) ?? "0");
          int minutes = int.parse(match.group(2) ?? "0");
          int seconds = int.parse(match.group(3) ?? "0");
          durationInSeconds = hours * 3600 + minutes * 60 + seconds;
        }
      } catch (e) {
        print('BlobRepository: Error getting audio duration: $e');
      }

      // Compress audio with multiple attempts
      final originalSize = await file.length();
      File? bestCompressedFile;
      int bestSize = originalSize;

      // Try different compression levels (most aggressive first)
      final compressionLevels = [
        {'bitrate': '24k', 'channels': '1', 'sample_rate': '22050'},
        {'bitrate': '32k', 'channels': '1', 'sample_rate': '44100'},
        {'bitrate': '48k', 'channels': '2', 'sample_rate': '44100'},
      ];

      for (int i = 0; i < compressionLevels.length; i++) {
        final level = compressionLevels[i];
        final tempPath = '${audioDir.path}/${fileId}_temp_$i.mp3';

        try {
          final session = await FFmpegKit.execute(
              '-i ${file.path} -b:a ${level['bitrate']} -ac ${level['channels']} -ar ${level['sample_rate']} $tempPath');

          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            final compressedFile = File(tempPath);
            if (await compressedFile.exists()) {
              final compressedSize = await compressedFile.length();
              print(
                  'BlobRepository: Compression level $i: ${compressedSize} bytes');

              if (compressedSize < bestSize) {
                // Delete previous best if exists
                if (bestCompressedFile != null) {
                  await bestCompressedFile.delete();
                }
                bestCompressedFile = compressedFile;
                bestSize = compressedSize;

                // If we're under the limit, we can stop
                if (bestSize <= maxAudioSize) {
                  break;
                }
              } else {
                // Delete this attempt as it's not better
                await compressedFile.delete();
              }
            }
          }
        } catch (e) {
          print('BlobRepository: Compression level $i failed: $e');
        }
      }

      Map<String, dynamic> documentData;

      if (bestCompressedFile != null && bestSize <= firestoreDocLimit) {
        // Store compressed audio in Firestore as base64
        print('BlobRepository: Storing compressed audio in Firestore');

        try {
          final compressedBytes = await bestCompressedFile.readAsBytes();
          final base64Audio = base64Encode(compressedBytes);

          documentData = {
            'data': base64Audio,
            'path': path,
            'contentType': 'audio/mpeg',
            'createdAt': FieldValue.serverTimestamp(),
            'size': bestSize,
            'duration': durationInSeconds,
            'isCompressed': true,
            'originalSize': originalSize,
            'storageType': 'firestore_blob',
          };

          // Clean up compressed file
          await bestCompressedFile.delete();
        } catch (e) {
          print('BlobRepository: Error processing compressed audio: $e');
          await bestCompressedFile.delete();
          throw Exception('Error processing audio data');
        }
      } else if (bestCompressedFile != null) {
        // Store locally if still too large for Firestore
        print('BlobRepository: Storing audio file locally');

        final localPath = '${audioDir.path}/$fileId.mp3';
        await bestCompressedFile.copy(localPath);
        await bestCompressedFile.delete();

        documentData = {
          'path': path,
          'contentType': 'audio/mpeg',
          'createdAt': FieldValue.serverTimestamp(),
          'size': bestSize,
          'duration': durationInSeconds,
          'isLocalStorage': true,
          'localPath': localPath,
          'originalSize': originalSize,
          'storageType': 'local_audio',
        };
      } else {
        throw Exception('Audio file too large and compression failed');
      }

      // Store in Firestore
      await firestore
          .collection('users')
          .doc(userId)
          .collection('media')
          .doc(fileId)
          .set(documentData);

      print('BlobRepository: Audio stored with ID: $fileId');
      return fileId;
    } catch (e) {
      print('BlobRepository: Error storing audio: $e');
      if (context != null) {
        showSnackBar(context, 'Error storing audio: $e');
      }
      rethrow;
    }
  }

  // Improved blob retrieval with better memory management
  Future<Uint8List?> getBlob(String fileId, String userId) async {
    try {
      print('BlobRepository: Retrieving blob with ID: $fileId');

      // Try to get from user's media collection
      final docSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('media')
          .doc(fileId)
          .get();

      Map<String, dynamic>? data;

      if (!docSnapshot.exists) {
        print(
            'BlobRepository: Blob not found in user media, searching globally');

        // Fallback: check other users' media collections
        final querySnapshot = await firestore
            .collectionGroup('media')
            .where(FieldPath.documentId, isEqualTo: fileId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          print('BlobRepository: Blob not found anywhere');
          return null;
        }

        data = querySnapshot.docs.first.data();
      } else {
        data = docSnapshot.data();
      }

      if (data == null) {
        print('BlobRepository: Invalid blob data');
        return null;
      }

      return await _processBlobData(data);
    } catch (e) {
      print('BlobRepository: Error retrieving blob: $e');
      return null;
    }
  }

  // Enhanced blob data processing with better error handling and memory management
  Future<Uint8List?> _processBlobData(Map<String, dynamic> data) async {
    try {
      // Case 1: Regular blob stored as base64
      if (data.containsKey('data')) {
        final base64String = data['data'] as String;

        // Check estimated size before decoding
        final estimatedSize = (base64String.length * 3) ~/ 4;
        if (estimatedSize > 10 * 1024 * 1024) {
          // 10MB limit
          print('BlobRepository: Base64 data too large: $estimatedSize bytes');
          return null;
        }

        try {
          return base64Decode(base64String);
        } catch (e) {
          print('BlobRepository: Error decoding base64: $e');
          return null;
        }
      }

      // Case 2: Video thumbnail
      else if (data.containsKey('thumbnail')) {
        final base64Thumbnail = data['thumbnail'] as String;
        try {
          return base64Decode(base64Thumbnail);
        } catch (e) {
          print('BlobRepository: Error decoding thumbnail: $e');
          return null;
        }
      }

      // Case 3: Local storage reference
      else if (data.containsKey('localPath')) {
        final localPath = data['localPath'] as String;
        final file = File(localPath);

        if (await file.exists()) {
          try {
            final fileSize = await file.length();
            if (fileSize > 10 * 1024 * 1024) {
              // 10MB limit
              print('BlobRepository: Local file too large: $fileSize bytes');
              return null;
            }

            return await file.readAsBytes();
          } catch (e) {
            print('BlobRepository: Error reading local file: $e');
            return null;
          }
        } else {
          print('BlobRepository: Local file does not exist: $localPath');
          return null;
        }
      }

      print('BlobRepository: Unknown blob data format');
      return null;
    } catch (e) {
      print('BlobRepository: Error processing blob data: $e');
      return null;
    }
  }

  // Clean up orphaned local files and manage storage
  Future<void> cleanupOrphanedFiles() async {
    try {
      print('BlobRepository: Starting cleanup...');

      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/videos');
      final audioDir = Directory('${appDir.path}/audio');

      // Get all file IDs from Firestore
      final allMediaQuery = await firestore
          .collectionGroup('media')
          .where('isLocalStorage', isEqualTo: true)
          .limit(1000) // Limit to prevent memory issues
          .get();

      final validFileIds = allMediaQuery.docs.map((doc) => doc.id).toSet();
      print('BlobRepository: Found ${validFileIds.length} valid files');

      int deletedCount = 0;

      // Clean up video files
      if (await videoDir.exists()) {
        await for (final file in videoDir.list()) {
          if (file is File) {
            final fileName = file.path.split('/').last;
            final fileId = fileName.split('.').first;
            if (!validFileIds.contains(fileId)) {
              try {
                await file.delete();
                deletedCount++;
                print('BlobRepository: Deleted orphaned video: $fileName');
              } catch (e) {
                print('BlobRepository: Error deleting video file: $e');
              }
            }
          }
        }
      }

      // Clean up audio files
      if (await audioDir.exists()) {
        await for (final file in audioDir.list()) {
          if (file is File) {
            final fileName = file.path.split('/').last;
            final fileId = fileName.split('.').first;
            if (!validFileIds.contains(fileId)) {
              try {
                await file.delete();
                deletedCount++;
                print('BlobRepository: Deleted orphaned audio: $fileName');
              } catch (e) {
                print('BlobRepository: Error deleting audio file: $e');
              }
            }
          }
        }
      }

      print(
          'BlobRepository: Cleanup completed. Deleted $deletedCount orphaned files');
    } catch (e) {
      print('BlobRepository: Error during cleanup: $e');
    }
  }

  // Get storage statistics with better error handling
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/videos');
      final audioDir = Directory('${appDir.path}/audio');

      int videoCount = 0;
      int audioCount = 0;
      int totalVideoSize = 0;
      int totalAudioSize = 0;

      // Count video files
      if (await videoDir.exists()) {
        try {
          await for (final file in videoDir.list()) {
            if (file is File) {
              videoCount++;
              totalVideoSize += await file.length();
            }
          }
        } catch (e) {
          print('BlobRepository: Error reading video directory: $e');
        }
      }

      // Count audio files
      if (await audioDir.exists()) {
        try {
          await for (final file in audioDir.list()) {
            if (file is File) {
              audioCount++;
              totalAudioSize += await file.length();
            }
          }
        } catch (e) {
          print('BlobRepository: Error reading audio directory: $e');
        }
      }

      return {
        'videoCount': videoCount,
        'audioCount': audioCount,
        'totalVideoSize': totalVideoSize,
        'totalAudioSize': totalAudioSize,
        'totalSize': totalVideoSize + totalAudioSize,
        'videoSizeMB': (totalVideoSize / (1024 * 1024)).toStringAsFixed(2),
        'audioSizeMB': (totalAudioSize / (1024 * 1024)).toStringAsFixed(2),
        'totalSizeMB': ((totalVideoSize + totalAudioSize) / (1024 * 1024))
            .toStringAsFixed(2),
        'limits': {
          'maxImageSize': '${(maxImageSize / 1024).toStringAsFixed(0)}KB',
          'maxVideoSize':
              '${(maxVideoSize / (1024 * 1024)).toStringAsFixed(1)}MB',
          'maxAudioSize': '${(maxAudioSize / 1024).toStringAsFixed(0)}KB',
        }
      };
    } catch (e) {
      print('BlobRepository: Error getting storage stats: $e');
      return {'error': e.toString()};
    }
  }

  // Helper to determine file content type
  String _getContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }

  // Helper method to clear cache when memory is low
  Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final file in tempDir.list()) {
          if (file is File && file.path.contains('flutter_cache')) {
            try {
              await file.delete();
            } catch (e) {
              print('BlobRepository: Error deleting cache file: $e');
            }
          }
        }
      }
      print('BlobRepository: Cache cleared');
    } catch (e) {
      print('BlobRepository: Error clearing cache: $e');
    }
  }
}
