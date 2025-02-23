import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:whatsapppp/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/models/user_model.dart';
import 'package:whatsapppp/screens/mobile_screen_layout.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  ),
);

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({
    required this.auth,
    required this.firestore,
  });

  Future<UserModel?> getCurrentUserData() async {
    if (auth.currentUser == null) return null;

    var userData =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();

    UserModel? user;
    if (userData.data() != null) {
      user = UserModel.fromMap(userData.data()!);
    }

    return user;
  }

  // // verify phone number which will take input from the phone number and then send the OTP to the phone number
  // // after otp has matches that the user has entered, then the user will be signed in
  // // just like sign in with email and password
  // void signInWithPhone(BuildContext context, String phoneNumber) async {
  //   try {
  //     await auth.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       verificationCompleted: (PhoneAuthCredential credential) {
  //         // user input correct phone number
  //         auth.signInWithCredential(credential);
  //       },
  //       verificationFailed: (e) {
  //         throw Exception(e.message);
  //       },
  //       codeSent: (String verificationId, int? resendToken) async {
  //         // then the OTP will send and the user will be navigated to the OTP screen
  //         Navigator.pushNamed(
  //           context,
  //           OTPScreen.routeName,
  //           arguments: verificationId,
  //         );
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {},
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     showSnackBar(context, e.message!);
  //   }
  // }

  // void verifyOTP({
  //   required BuildContext context,
  //   required String verificationId,
  //   required String userOTP,
  // }) async {
  //   try {
  //     PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //       verificationId: verificationId,
  //       smsCode: userOTP,
  //     );
  //     await auth.signInWithCredential(credential);
  //     Navigator.pushNamedAndRemoveUntil(
  //       context,
  //       UserInformationScreen.routeName,
  //       (route) => false,
  //     );
  //   } catch (e) {
  //     showSnackBar(context, e.toString());
  //   }
  // }

  Future<void> signUpWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required Ref ref,
    File? profilePic,
  }) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String photoUrl =
          'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg';

      if (profilePic != null) {
        photoUrl = await ref
            .read(CommonFirebaseStorageRepositoryProvider)
            .storeFileToFirebase('profilePic/$uid', profilePic);
      }

      // Create data map first
      Map<String, dynamic> userData = {
        'name': name,
        'uid': uid,
        'profilePic': photoUrl,
        'isOnline': true,
        'email': email,
        'phoneNumber': phoneNumber,
        'groupId': [], // Initialize as empty array
      };

      // Save to Firebase using set with merge option
      await firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MobileLayoutScreen()),
        (route) => false,
      );

      showSnackBar(context, 'User created successfully');
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MobileLayoutScreen()),
        (route) => false,
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void saveUserDataToFirebase({
    required String name,
    required File? profilePic,
    required Ref ref,
    required BuildContext context,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      String email = auth.currentUser!.email ?? '';
      String photoUrl =
          'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg';

      if (profilePic != null) {
        photoUrl = await ref
            .read(CommonFirebaseStorageRepositoryProvider)
            .storeFileToFirebase('profilePic/$uid', profilePic);
      }

      // Create a Map of the data first
      Map<String, dynamic> userData = {
        'name': name,
        'uid': uid,
        'profilePic': photoUrl,
        'isOnline': true,
        'email': email,
        'phoneNumber': auth.currentUser!.phoneNumber
            .toString(), // Handle null phone number
        'groupId': [], // Initialize as empty array
      };

      // Create user model
      UserModel(
        name: name,
        uid: uid,
        profilePic: photoUrl,
        isOnline: true,
        email: email,
        groupId: [],
        phoneNumber: auth.currentUser!.phoneNumber.toString(),
      );

      // Save to Firebase using set with merge option
      await firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MobileLayoutScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
}
