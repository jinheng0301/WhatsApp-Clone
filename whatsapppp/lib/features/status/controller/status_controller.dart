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

  // Get statuses stream
  Stream<List<Status>> getStatus() {
    return statusRepository.getStatus();
  }

  // Method to get blob data by ID
  Future<Map<String, dynamic>?> getStatusBlobData(String blobId) {
    return statusRepository.getStatusBlobData(blobId);
  }
}
