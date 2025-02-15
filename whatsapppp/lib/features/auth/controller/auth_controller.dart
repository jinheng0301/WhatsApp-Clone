import 'dart:io';

import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:whatsapppp/features/auth/repository/auth_repository.dart';

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepossitoryProvider);
  return AuthController(
    authRepository: authRepository,
    ref: ref,
  );
});

class AuthController {
  late final AuthRepository authRepository;
  final Ref ref;

  AuthController({
    required this.authRepository,
    required this.ref,
  });

  void signInWithPhone(BuildContext context, String phoneNumber) {
    authRepository.signInWithPhone(context, phoneNumber);
  }

  void verifyOTP({
    required BuildContext context,
    required String verificationId,
    required String userOTP,
  }) {
    authRepository.verifyOTP(
      context: context,
      verificationId: verificationId,
      userOTP: userOTP,
    );
  }

  void saveUserDataToFirebase(
    BuildContext context,
    String name,
    File? profilePic,
  ) {
    authRepository.saveUserDataToFirebase(
      name: name,
      profilePic: profilePic,
      context: context,
      ref: ref,
    );
  }
}
