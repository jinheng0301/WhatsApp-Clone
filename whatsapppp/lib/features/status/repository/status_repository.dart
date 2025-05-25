import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapppp/models/status_model.dart';

final statusRepositoryProvider = Provider(
  (ref) => StatusRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    ref: ref,
  ),
);

class StatusRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Ref ref;

  StatusRepository({
    required this.firestore,
    required this.auth,
    required this.ref,
  });

  void uploadStatusWithBlob({
    required String username,
    required String profilePic,
    required String phoneNumber,
    required File statusImage,
    required BuildContext context,
  }) async {
    try {
      var statusId = const Uuid().v1();
      String uid = auth.currentUser!.uid;

      print(
          'StatusRepository: Starting blob status upload for statusId: $statusId');

      // Convert image to base64
      List<int> imageBytes = await statusImage.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      print(
          'StatusRepository: Image converted to base64, size: ${base64Image.length}');

      // Determine content type based on file extension
      String contentType = 'image/jpeg'; // default
      String extension = statusImage.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }

      // Create blob data structure
      Map<String, dynamic> blobData = {
        'data': base64Image,
        'type': contentType,
        'size': imageBytes.length,
        'fileName':
            'status_${statusId}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': uid,
        'localPath': statusImage.path,
      };

      print('StatusRepository: Saving blob data to status collection');

      // Save blob to status collection's media subcollection
      String blobId = const Uuid().v1();
      await firestore
          .collection('status')
          .doc('media')
          .collection('blobs')
          .doc(blobId)
          .set(blobData);

      print('StatusRepository: Blob saved with ID: $blobId');

      // For email/password auth, we'll make status visible to all registered users
      // or you can implement a friend system later
      List<String> uidWhoCanSee = [];

      // Option 1: Make visible to all users (public statuses)
      var allUsers = await firestore.collection('users').get();
      for (var doc in allUsers.docs) {
        if (doc.id != uid) {
          // Don't include current user
          uidWhoCanSee.add(doc.id);
        }
      }

      // Option 2: If you want to use phone contacts (uncomment this and comment above)
      /*
      List<Contact> contacts = [];
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
        
        for (var contact in contacts) {
          if (contact.phones.isNotEmpty) {
            String contactPhone = contact.phones[0].number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
            
            // Try to find user by phone number
            var userQuery = await firestore
                .collection('users')
                .where('phoneNumber', isEqualTo: contactPhone)
                .get();
                
            for (var doc in userQuery.docs) {
              if (doc.id != uid) {
                uidWhoCanSee.add(doc.id);
              }
            }
          }
        }
      }
      */

      print(
          'StatusRepository: Found ${uidWhoCanSee.length} users who can see status');

      // Check for existing statuses within 24 hours
      List<String> statusBlobIds = [];
      var statusesSnapshot = await firestore
          .collection('status')
          .where('uid', isEqualTo: uid)
          .where('createdAt',
              isGreaterThan: DateTime.now().subtract(Duration(hours: 24)))
          .get();

      if (statusesSnapshot.docs.isNotEmpty) {
        // Update existing status with new blob ID
        Status existingStatus = Status.fromMap(statusesSnapshot.docs[0].data());
        statusBlobIds = List<String>.from(existingStatus.photoUrl);
        statusBlobIds.add(blobId);

        print('StatusRepository: Updating existing status with new blob');

        await firestore
            .collection('status')
            .doc(statusesSnapshot.docs[0].id)
            .update({
          'photoUrl': statusBlobIds,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // Create new status
        statusBlobIds = [blobId];

        print('StatusRepository: Creating new status');

        Status status = Status(
          uid: uid,
          username: username,
          phoneNumber: phoneNumber,
          photoUrl: statusBlobIds,
          createdAt: DateTime.now(),
          profilePic: profilePic,
          statusId: statusId,
          whoCanSee: uidWhoCanSee,
        );

        await firestore.collection('status').doc(statusId).set(status.toMap());
      }

      print('StatusRepository: Blob status upload completed successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('StatusRepository: Error uploading blob status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Keep original method for backward compatibility
  void uploadStatus({
    required String username,
    required String profilePic,
    required String phoneNumber,
    required File statusImage,
    required BuildContext context,
  }) async {
    uploadStatusWithBlob(
      username: username,
      profilePic: profilePic,
      phoneNumber: phoneNumber,
      statusImage: statusImage,
      context: context,
    );
  }

  // Method to get status blob data
  Future<Map<String, dynamic>?> getStatusBlobData(String blobId) async {
    try {
      final doc = await firestore
          .collection('status')
          .doc('media')
          .collection('blobs')
          .doc(blobId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('StatusRepository: Error getting blob data: $e');
      return null;
    }
  }

  // Method to get current user's own statuses
  Future<List<Status>> getCurrentUserStatuses() async {
    List<Status> statusData = [];

    try {
      String? currentUserId = auth.currentUser?.uid;
      if (currentUserId == null) {
        print('StatusRepository: No authenticated user');
        return statusData;
      }

      print(
          'StatusRepository: Getting statuses for current user: $currentUserId');

      final twentyFourHoursAgo =
          DateTime.now().subtract(const Duration(hours: 24));

      var userStatuses = await firestore
          .collection('status')
          .where('uid', isEqualTo: currentUserId)
          .where('createdAt',
              isGreaterThan: twentyFourHoursAgo.millisecondsSinceEpoch)
          .get();

      print(
          'StatusRepository: Found ${userStatuses.docs.length} current user statuses');

      for (var doc in userStatuses.docs) {
        try {
          Status status = Status.fromMap(doc.data());
          statusData.add(status);
          print('StatusRepository: Added current user status');
        } catch (e) {
          print(
              'StatusRepository: Error parsing current user status ${doc.id}: $e');
        }
      }

      statusData.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return statusData;
    } catch (e) {
      print('StatusRepository: Error getting current user statuses: $e');
      return statusData;
    }
  }

  // Method to get all statuses that current user can see
  Future<List<Status>> getAllVisibleStatuses() async {
    List<Status> statusData = [];

    try {
      String? currentUserId = auth.currentUser?.uid;
      if (currentUserId == null) {
        print('StatusRepository: No authenticated user');
        return statusData;
      }

      print(
          'StatusRepository: Getting all statuses visible to current user: $currentUserId');

      final twentyFourHoursAgo =
          DateTime.now().subtract(const Duration(hours: 24));

      // Get all recent statuses where current user is in whoCanSee array
      var visibleStatuses = await firestore
          .collection('status')
          .where('whoCanSee', arrayContains: currentUserId)
          .where('createdAt',
              isGreaterThan: twentyFourHoursAgo.millisecondsSinceEpoch)
          .get();

      print(
          'StatusRepository: Found ${visibleStatuses.docs.length} visible statuses');

      for (var doc in visibleStatuses.docs) {
        try {
          Status status = Status.fromMap(doc.data());
          statusData.add(status);
          print('StatusRepository: Added status from ${status.username}');
        } catch (e) {
          print('StatusRepository: Error parsing status ${doc.id}: $e');
        }
      }

      statusData.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return statusData;
    } catch (e) {
      print('StatusRepository: Error getting visible statuses: $e');
      return statusData;
    }
  }

  // Combined method to get both current user's statuses and others' statuses
  Future<List<Status>> getStatusDebug(BuildContext context) async {
    List<Status> statusData = [];

    try {
      print('StatusRepository DEBUG: Starting getStatus method');

      String? currentUserId = auth.currentUser?.uid;
      if (currentUserId == null) {
        print('StatusRepository DEBUG: No authenticated user');
        return statusData;
      }

      print('StatusRepository DEBUG: Current user ID: $currentUserId');

      // Get current user info
      var currentUserDoc =
          await firestore.collection('users').doc(currentUserId).get();
      if (currentUserDoc.exists) {
        var userData = currentUserDoc.data()!;
        print(
            'StatusRepository DEBUG: Current user: ${userData['name']} (${userData['email']})');
      }

      // First, let's check what statuses exist in the database
      print('StatusRepository DEBUG: Checking all statuses in database...');
      var allStatuses = await firestore.collection('status').get();
      print(
          'StatusRepository DEBUG: Total statuses in database: ${allStatuses.docs.length}');

      final twentyFourHoursAgo =
          DateTime.now().subtract(const Duration(hours: 24));
      print(
          'StatusRepository DEBUG: Looking for statuses after ${twentyFourHoursAgo.toIso8601String()}');

      for (var doc in allStatuses.docs) {
        var data = doc.data();
        var createdAt = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
        var isRecent = createdAt.isAfter(twentyFourHoursAgo);

        print('StatusRepository DEBUG: Status doc ${doc.id}:');
        print('  - username: ${data['username']}');
        print('  - uid: ${data['uid']}');
        print('  - createdAt: ${createdAt.toIso8601String()}');
        print('  - isRecent (within 24h): $isRecent');
        print('  - photoUrl length: ${(data['photoUrl'] as List).length}');
        print('  - whoCanSee length: ${(data['whoCanSee'] as List).length}');
        print(
            '  - whoCanSee contains current user: ${(data['whoCanSee'] as List).contains(currentUserId)}');
        print('  - is current user\'s status: ${data['uid'] == currentUserId}');

        if (isRecent) {
          try {
            Status status = Status.fromMap(data);

            // Include status if:
            // 1. It's the current user's own status, OR
            // 2. Current user is in the whoCanSee list
            if (status.uid == currentUserId ||
                status.whoCanSee.contains(currentUserId)) {
              statusData.add(status);
              print(
                  'StatusRepository DEBUG: ADDED status from ${status.username}');
            } else {
              print(
                  'StatusRepository DEBUG: SKIPPED status from ${status.username} (not visible to current user)');
            }
          } catch (e) {
            print('StatusRepository DEBUG: Error parsing status ${doc.id}: $e');
          }
        }
      }

      print('StatusRepository DEBUG: Final status count: ${statusData.length}');
      statusData.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return statusData;
    } catch (e, stackTrace) {
      print('StatusRepository DEBUG: Major error in getStatus: $e');
      print('StatusRepository DEBUG: Stack trace: $stackTrace');
      return statusData;
    }
  }
}
