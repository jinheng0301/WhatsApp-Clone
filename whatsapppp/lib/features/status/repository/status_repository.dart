import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapppp/models/status_model.dart';
import 'package:whatsapppp/models/user_model.dart';

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

      // Get contacts for visibility
      List<Contact> contacts = [];
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      List<String> uidWhoCanSee = [];
      for (int i = 0; i < contacts.length; i++) {
        if (contacts[i].phones.isNotEmpty) {
          var userDataFirebase = await firestore
              .collection('users')
              .where(
                'phoneNumber',
                isEqualTo: contacts[i].phones[0].number.replaceAll(' ', ''),
              )
              .get();

          if (userDataFirebase.docs.isNotEmpty) {
            var userData = UserModel.fromMap(userDataFirebase.docs[0].data());
            uidWhoCanSee.add(userData.uid);
          }
        }
      }

      print(
          'StatusRepository: Found ${uidWhoCanSee.length} contacts who can see status');

      // Check for existing statuses within 24 hours
      List<String> statusBlobIds = [];
      var statusesSnapshot = await firestore
          .collection('status')
          .where('uid', isEqualTo: uid)
          .where(
            'createdAt',
            isGreaterThan: DateTime.now().subtract(Duration(hours: 24)),
          )
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
    // Call the new blob method
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

  // Method to get all statuses (for status screen)
  Stream<List<Status>> getStatus() {
    return firestore
        .collection('status')
        .where(
          'createdAt',
          isGreaterThan: DateTime.now()
              .subtract(Duration(hours: 24))
              .millisecondsSinceEpoch,
        )
        .snapshots()
        .map((event) {
      List<Status> statuses = [];
      for (var document in event.docs) {
        statuses.add(Status.fromMap(document.data()));
      }
      return statuses;
    });
  }
}
