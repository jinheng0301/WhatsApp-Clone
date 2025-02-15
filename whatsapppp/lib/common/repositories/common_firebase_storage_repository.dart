import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final CommonFirebaseStorageRepositoryProvider = Provider(
  (ref) => CommonFirebaseStorageRepository(
    firebaseStorage: FirebaseStorage.instance,
  ),
);

class CommonFirebaseStorageRepository {
  final FirebaseStorage firebaseStorage;

  CommonFirebaseStorageRepository({required this.firebaseStorage});

  Future<String> storeFileToFirebase(String ref, File file) async {
    UploadTask uploadTask = firebaseStorage.ref().child(ref).putFile(file);
    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
    // returning a String in a async function that makes it a Future<String>
  }
}
