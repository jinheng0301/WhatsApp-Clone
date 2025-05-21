import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapppp/common/utils/utils.dart';

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

  // Store file as BLOB in Firestore
  Future<String> storeFileAsBlob(
    String path,
    File file,
    BuildContext? context,
  ) async {
    try {
      print('BlobRepository: Reading file into memory');

      // Read file as bytes
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;

      // Firestore document size limit is 1MB
      // We'll use a smaller threshold to be safe
      final maxSize = 800 * 1024; // 800KB to be safe

      print('BlobRepository: File size: $fileSize bytes');

      // Generate a unique ID for this file
      final fileId = const Uuid().v1();
      final userId = path.split('/')[2]; // Extract user ID from path

      if (fileSize <= maxSize) {
        // File is small enough to store directly
        print('BlobRepository: Storing small file directly');
        final base64File = base64Encode(fileBytes);

        // Store in user's media subcollection instead of dedicated blobs collection
        await firestore
            .collection('users')
            .doc(userId)
            .collection('media')
            .doc(fileId)
            .set({
          'data': base64File,
          'path': path,
          'contentType': _getContentType(file.path),
          'createdAt': FieldValue.serverTimestamp(),
          'size': fileSize,
        });
      } else {
        // File is too large, notify user
        print('BlobRepository: File is too large ($fileSize bytes)');
        if (context != null) {
          showSnackBar(context, 'File is too large (max 800KB)');
        }
        throw Exception('File is too large for BLOB storage (max 800KB)');
      }

      print('BlobRepository: Successfully stored file with ID: $fileId');
      return fileId;
    } catch (e) {
      print('BlobRepository: Error storing file as blob: $e');
      if (context != null) {
        showSnackBar(context, 'Error storing file: $e');
      }
      rethrow;
    }
  }

  // Retrieve BLOB from Firestore
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

      if (!docSnapshot.exists) {
        print('BlobRepository: Blob not found in user media');

        // As a fallback, check other users' media collections
        // This is needed for group chats or when receiving media from others
        final querySnapshot = await firestore
            .collectionGroup('media')
            .where(FieldPath.documentId, isEqualTo: fileId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          print('BlobRepository: Blob not found anywhere');
          return null;
        }

        final data = querySnapshot.docs.first.data();

        if (!data.containsKey('data')) {
          print('BlobRepository: Invalid blob data');
          return null;
        }

        // Decode base64 string back to bytes
        final base64String = data['data'] as String;
        return base64Decode(base64String);
      } else {
        final data = docSnapshot.data();

        if (data == null || !data.containsKey('data')) {
          print('BlobRepository: Invalid blob data');
          return null;
        }

        // Decode base64 string back to bytes
        final base64String = data['data'] as String;
        return base64Decode(base64String);
      }
    } catch (e) {
      print('BlobRepository: Error retrieving blob: $e');
      return null;
    }
  }

  // Helper to determine file content type
  String _getContentType(String filePath) {
    if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (filePath.endsWith('.png')) {
      return 'image/png';
    } else if (filePath.endsWith('.gif')) {
      return 'image/gif';
    } else if (filePath.endsWith('.mp4')) {
      return 'video/mp4';
    } else if (filePath.endsWith('.mp3') || filePath.endsWith('.aac')) {
      return 'audio/mpeg';
    } else {
      return 'application/octet-stream';
    }
  }
}
