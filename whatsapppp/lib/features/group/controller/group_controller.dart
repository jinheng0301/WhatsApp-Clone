import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:riverpod/riverpod.dart';
import 'package:whatsapppp/features/group/repository/group_repository.dart';

final groupControllerProvider = Provider(
  (ref) => GroupController(
    groupRepository: ref.watch(groupRepositoryProvider),
    ref: ref,
  ),
);

class GroupController {
  final GroupRepository groupRepository;
  final Ref ref;

  GroupController({
    required this.groupRepository,
    required this.ref,
  });

  void createGroup(
    BuildContext context,
    String name,
    File? profilePic,
    List<Contact> selectedContacts,
  ) {
    groupRepository.createGroup(
      context,
      name,
      profilePic,
      selectedContacts,
    );
  }
}
