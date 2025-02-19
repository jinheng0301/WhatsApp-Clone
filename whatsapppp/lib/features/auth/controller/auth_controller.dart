import 'dart:io';

import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:whatsapppp/features/auth/repository/auth_repository.dart';
import 'package:whatsapppp/models/user_model.dart';

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(
    authRepository: authRepository,
    ref: ref,
  );
});

final userDataAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getUserData();
});

class AuthController {
 final AuthRepository authRepository;
  final Ref ref;

  AuthController({
    required this.authRepository,
    required this.ref,
  });

  // get user data from firebase
  Future<UserModel?> getUserData() async {
    UserModel? user = await authRepository.getCurrentUserData();
    return user;
  }

  // void signInWithPhone(BuildContext context, String phoneNumber) {
  //   authRepository.signInWithPhone(context, phoneNumber);
  // }

  // void verifyOTP({
  //   required BuildContext context,
  //   required String verificationId,
  //   required String userOTP,
  // }) {
  //   authRepository.verifyOTP(
  //     context: context,
  //     verificationId: verificationId,
  //     userOTP: userOTP,
  //   );
  // }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
    File? profilePic,
  }) async {
    return await authRepository.signUpWithEmail(
      email: email,
      password: password,
      name: name,
      context: context,
      profilePic: profilePic,
      ref: ref,
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    return await authRepository.signInWithEmail(
      email: email,
      password: password,
      context: context,
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
