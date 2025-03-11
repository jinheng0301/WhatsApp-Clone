import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod/riverpod.dart';

final CommonFirebaseStorageRepositoryProvider = Provider(
  (ref) => CommonFirebaseStorageRepository(
    firebaseStorage: FirebaseStorage.instance,
  ),
);

class CommonFirebaseStorageRepository {
  final FirebaseStorage firebaseStorage;

  CommonFirebaseStorageRepository({
    required this.firebaseStorage,
  });

  Future<String> storeFileToFirebase(String path, File file) async {
    UploadTask uploadTask = firebaseStorage.ref().child(path).putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
