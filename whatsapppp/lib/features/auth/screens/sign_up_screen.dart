import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/common/widgets/custom_button.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  static const routeName = '/sign-up-screen';
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? profilePic;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  // pick image from gallery
  void selectImage() async {
    profilePic = await pickImageFromGallery(context);
    setState(() {});
  }

  void signUp() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider).signUpWithEmail(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            name: nameController.text.trim(),
            context: context,
            profilePic: profilePic,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    profilePic != null
                        ? CircleAvatar(
                            backgroundImage: FileImage(profilePic!),
                            radius: 70,
                          )
                        : CircleAvatar(
                            radius: 70,
                            backgroundImage: NetworkImage(
                              'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885__480.jpg',
                            ),
                          ),
                    Positioned(
                      bottom: -10,
                      left: 80,
                      child: IconButton(
                        onPressed: selectImage,
                        icon: Icon(Icons.add_a_photo),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showSnackBar(context, 'Please enter your name');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showSnackBar(context, 'Please enter your email');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showSnackBar(
                        context,
                        'Please enter your password',
                      );
                    }
                    if (value!.length < 6) {
                      showSnackBar(
                        context,
                        'Password must be at least 6 characters',
                      );
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                CustomButton(
                  onPressed: signUp,
                  text: 'Sign Up',
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
