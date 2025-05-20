import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/models/user_model.dart';

final selectContactRepositoryProvider = Provider(
  (ref) => SelectContactRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class SelectContactRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SelectContactRepository({
    required this.firestore,
    required this.auth,
  });

  // Get all registered users except the current user
  Future<List<UserModel>> getRegisteredUsers() async {
    try {
      var usersCollection = await firestore.collection('users').get();
      List<UserModel> registeredUsers = [];

      for (var userDoc in usersCollection.docs) {
        var userData = UserModel.fromMap(userDoc.data());
        // Don't include the current user in the list
        if (userData.uid != auth.currentUser!.uid) {
          registeredUsers.add(userData);
        }
      }

      return registeredUsers;
    } catch (e) {
      throw e;
    }
  }

  // Search users by name or phone number
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      var usersCollection = await firestore.collection('users').get();
      List<UserModel> matchedUsers = [];

      for (var userDoc in usersCollection.docs) {
        var userData = UserModel.fromMap(userDoc.data());
        // Don't include the current user in the list
        if (userData.uid != auth.currentUser!.uid) {
          // Check if the query matches name or phone number
          if (userData.name.toLowerCase().contains(query.toLowerCase()) ||
              userData.phoneNumber.contains(query)) {
            matchedUsers.add(userData);
          }
        }
      }

      return matchedUsers;
    } catch (e) {
      throw e;
    }
  }
}
