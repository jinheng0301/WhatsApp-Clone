import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/features/select_contacts/repository/select_contact_repository.dart';
import 'package:whatsapppp/features/chat/screens/mobile_chat_screen.dart';
import 'package:whatsapppp/models/user_model.dart';

final selectContactControllerProvider = Provider((ref) {
  final selectContactRepository = ref.watch(selectContactRepositoryProvider);
  return SelectContactController(
    ref: ref,
    selectContactRepository: selectContactRepository,
  );
});

// Provider for getting registered users
final getRegisteredUsersProvider = FutureProvider<List<UserModel>>((ref) {
  final selectContactController = ref.watch(selectContactControllerProvider);
  return selectContactController.getRegisteredUsers();
});

// Provider for searching users
final searchUsersProvider = FutureProvider.family<List<UserModel>, String>((ref, query) {
  final selectContactController = ref.watch(selectContactControllerProvider);
  return selectContactController.searchUsers(query);
});

class SelectContactController {
  final ProviderRef ref;
  final SelectContactRepository selectContactRepository;

  SelectContactController({
    required this.ref,
    required this.selectContactRepository,
  });

  // Get all registered users
  Future<List<UserModel>> getRegisteredUsers() async {
    return await selectContactRepository.getRegisteredUsers();
  }

  // Search users by name or phone
  Future<List<UserModel>> searchUsers(String query) async {
    return await selectContactRepository.searchUsers(query);
  }

  // Navigate to chat screen with selected user
  void selectUser(UserModel selectedUser, BuildContext context) {
    Navigator.pushNamed(
      context,
      MobileChatScreen.routeName,
      arguments: {
        'name': selectedUser.name,
        'uid': selectedUser.uid,
        'isGroupChat': false,
        'profilePic': selectedUser.profilePic,
      },
    );
  }
}