import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/repositories/common_firebase_storage_repository.dart';

class CommonFirebaseStorageRepositoryProvider {
  CommonFirebaseStorageRepositoryProvider._();

  static final provider = Provider((ref) => CommonFirebaseStorageRepository(ref.read));

  static final storeFileToFirebase = Provider.autoDispose<String>((ref) => ref.watch(provider).storeFileToFirebase);

  static final deleteFileFromFirebase = Provider.autoDispose<void>((ref) => ref.watch(provider).deleteFileFromFirebase);
}