import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:riverpod/riverpod.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/chat/screens/mobile_chat_screen.dart';
import 'package:whatsapppp/models/user_model.dart';

final selectContactRepositoryProvider = Provider(
  (ref) => SelectContactRepository(
    firestore: FirebaseFirestore.instance,
  ),
);

class SelectContactRepository {
  final FirebaseFirestore firestore;

  SelectContactRepository({required this.firestore});

  Future<List<Contact>> getContacts() async {
    List<Contact> contacts = [];
    try {
      if (await FlutterContacts.requestPermission()) {
        // request for gettting permission to access contacts
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return contacts;
  }

  void selectContact(Contact selectedContact, BuildContext context) async {
    try {
      // Debug logging
      debugPrint('Selecting contact: ${selectedContact.displayName}');

      // Check if contact has phone numbers
      if (selectedContact.phones.isEmpty) {
        showSnackBar(context, 'This contact does not have a phone number');
        return;
      }

      debugPrint('Contact phone: ${selectedContact.phones[0].number}');

      var userCollection = await firestore.collection('users').get();
      debugPrint('Found ${userCollection.docs.length} users in Firebase');

      bool isFound = false;

      for (var document in userCollection.docs) {
        var userData = UserModel.fromMap(document.data());
        debugPrint(
            'Comparing with user: ${userData.name}, phone: ${userData.phoneNumber}');

        // Format phone number by removing all non-digit characters except '+'
        String selectedPhoneNumber =
            selectedContact.phones[0].number.replaceAll(RegExp(r'[^\d+]'), '');

        debugPrint('Formatted phone: $selectedPhoneNumber');
        debugPrint('DB phone: ${userData.phoneNumber}');

        // Use a better phone number comparison
        if (isSamePhoneNumber(selectedPhoneNumber, userData.phoneNumber)) {
          debugPrint('Match found! Navigating to chat screen');
          isFound = true;
          Navigator.pushNamed(
            context,
            MobileChatScreen.routeName,
            arguments: {
              'name': userData.name,
              'uid': userData.uid,
              'isGroupChat': false,
              'profilePic': userData.profilePic,
            },
          );
          break;
        }
      }

      if (!isFound) {
        debugPrint('No matching user found in database');
        showSnackBar(context, 'This number does not exist in the app');
      }
    } catch (e) {
      debugPrint('Error in selectContact: $e');
      showSnackBar(context, e.toString());
    }
  }

  // Helper method for better phone number comparison
  bool isSamePhoneNumber(String phone1, String phone2) {
    // Remove all non-digit characters except '+'
    String cleanPhone1 = phone1.replaceAll(RegExp(r'[^\d+]'), '');
    String cleanPhone2 = phone2.replaceAll(RegExp(r'[^\d+]'), '');

    // If both have country codes, direct comparison
    if (cleanPhone1.startsWith('+') && cleanPhone2.startsWith('+')) {
      return cleanPhone1 == cleanPhone2;
    }

    // If one has country code and the other doesn't
    if (cleanPhone1.startsWith('+') && !cleanPhone2.startsWith('+')) {
      return cleanPhone1.endsWith(cleanPhone2);
    }

    if (!cleanPhone1.startsWith('+') && cleanPhone2.startsWith('+')) {
      return cleanPhone2.endsWith(cleanPhone1);
    }

    // If neither has country code, direct comparison
    return cleanPhone1 == cleanPhone2;
  }
}
