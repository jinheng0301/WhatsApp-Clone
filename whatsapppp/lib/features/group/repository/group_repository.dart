import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapppp/common/providers/common_firebase_storage_repository_provider.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/models/group.dart';

final groupRepositoryProvider = Provider(
  (ref) => GroupRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    ref: ref,
  ),
);

class GroupRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Ref ref;

  GroupRepository({
    required this.firestore,
    required this.auth,
    required this.ref,
  });

  void createGroup(
    BuildContext context,
    String name,
    File? profilePic,
    List<Contact> selectedContact,
  ) async {
    try {
      // Validate minimum group members (at least 2 members excluding creator)
      if (selectedContact.length < 2) {
        showSnackBar(
            context, 'A group must have at least 2 members besides yourself');
        return;
      }

      // Validate that a profile picture is provided
      List<String> uids = [];
      for (int i = 0; i < selectedContact.length; i++) {
        var userCollection = await firestore
            .collection('users')
            .where(
              'phoneNumber',
              isEqualTo: selectedContact[i].phones[0].number.replaceAll(
                    ' ',
                    '',
                  ),
            )
            .get();

        if (userCollection.docs.isNotEmpty && userCollection.docs[0].exists) {
          uids.add(userCollection.docs[0].data()['uid']);
        }
      }

      // Double-check that we have enough valid members after database lookup
      if (uids.length < 2) {
        showSnackBar(
          context,
          'Could not find enough registered users to create the group. Minimum 2 members required.',
        );
        return;
      }

      var groupId = const Uuid().v1();

      // Handle optional profile picture
      String profileUrl;
      if (profilePic != null) {
        profileUrl = await ref
            .read(CommonFirebaseStorageRepositoryProvider)
            .storeFileToFirebase(
              'group/$groupId',
              profilePic,
            );
      } else {
        // Use default group image URL
        profileUrl =
            'https://png.pngitem.com/pimgs/s/649-6490124_katie-notopoulos-katienotopoulos-i-write-about-tech-round.png';
      }

      GroupChat group = GroupChat(
        senderId: auth.currentUser!.uid,
        name: name,
        groupId: groupId,
        lastMessage: '',
        groupPic: profileUrl,
        membersUid: [auth.currentUser!.uid, ...uids],
        timeSent: DateTime.now(),
      );

      await firestore.collection('groups').doc(groupId).set(group.toMap());

      // Show success message
      showSnackBar(context, 'Group created successfully!');
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
}
