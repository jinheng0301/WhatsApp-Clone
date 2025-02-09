import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:whatsapppp/features/auth/repository/auth_repository.dart';

final authControllerProvider = Provider(
  (ref){
    final authRepository = ref.watch(authRepossitoryProvider);
    return AuthController(authRepository: authRepository);
  }
);

class AuthController { 
  late final AuthRepository authRepository;

  AuthController({required this.authRepository});

  void signInWithPhone(BuildContext context, String phoneNumber) {
    authRepository.signInWithPhone(context, phoneNumber);
  }
}
