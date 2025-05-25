import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/status/repository/status_repository.dart';
import 'package:whatsapppp/models/status_model.dart';

final statusControllerProvider = Provider((ref) {
  final statusRepository = ref.read(statusRepositoryProvider);
  return StatusController(
    statusRepository: statusRepository,
    ref: ref,
  );
});

class StatusController {
  final StatusRepository statusRepository;
  final Ref ref;

  StatusController({
    required this.statusRepository,
    required this.ref,
  });

  // Updated method to use blob storage by default
  void addStatus(File file, BuildContext context) {
    print('StatusController: Adding status with blob storage');
    ref.watch(userDataAuthProvider).whenData((value) {
      if (value != null) {
        statusRepository.uploadStatusWithBlob(
          username: value.name,
          profilePic: value.profilePic,
          phoneNumber: value.phoneNumber,
          statusImage: file,
          context: context,
        );
      } else {
        print('StatusController: User data not available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Method specifically for blob storage (for clarity)
  void addStatusWithBlob(File file, BuildContext context) {
    print(
        'StatusController: Adding status with blob storage (explicit method)');
    ref.watch(userDataAuthProvider).whenData((value) {
      if (value != null) {
        statusRepository.uploadStatusWithBlob(
          username: value.name,
          profilePic: value.profilePic,
          phoneNumber: value.phoneNumber,
          statusImage: file,
          context: context,
        );
      } else {
        print('StatusController: User data not available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Get all statuses (including current user's own statuses)
  Future<List<Status>> getStatus(BuildContext context) async {
    print('StatusController: Getting all statuses');
    List<Status> statuses = await statusRepository.getStatusDebug(context);
    print('StatusController: Retrieved ${statuses.length} statuses');
    return statuses;
  }

  // Get only current user's statuses
  Future<List<Status>> getCurrentUserStatuses() async {
    print('StatusController: Getting current user statuses');
    List<Status> statuses = await statusRepository.getCurrentUserStatuses();
    print(
        'StatusController: Retrieved ${statuses.length} current user statuses');
    return statuses;
  }

  // Get only other users' statuses that current user can see
  Future<List<Status>> getOtherUsersStatuses() async {
    print('StatusController: Getting other users statuses');
    List<Status> statuses = await statusRepository.getAllVisibleStatuses();
    print(
        'StatusController: Retrieved ${statuses.length} other users statuses');
    return statuses;
  }

  // Method to get blob data by ID
  Future<Map<String, dynamic>?> getStatusBlobData(String blobId) {
    return statusRepository.getStatusBlobData(blobId);
  }
}
