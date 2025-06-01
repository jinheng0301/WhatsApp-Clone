import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/common/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/auth/screens/sign_up_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login-screen';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Country? country;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void pickCountry() {
    showCountryPicker(
      context: context,
      onSelect: (Country _country) {
        setState(() {
          country = _country;
        });
      },
    );
  }

  void logIn() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider).signInWithEmail(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            context: context,
          );
    }
  }

  // void sendPhoneNumber() {
  //   String phoneNumber = phoneController.text.trim();
  //   if (country != null && phoneNumber.isNotEmpty) {
  //     // Provider ref -> interact provider with provider
  //     // Widget ref -> interact provider with widget
  //     ref
  //         .read(authControllerProvider)
  //         .signInWithPhone(context, '+${country!.phoneCode}$phoneNumber');
  //     // ! means nullable
  //   } else {
  //     showSnackBar(context, 'Fill out all the fields');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text(
                //   'WhatsApp will send an SMS message to verify your phone number.',
                // ),
                // SizedBox(height: 20),
                // TextButton(
                //   onPressed: () => pickCountry(),
                //   child: Text('Pick a country'),
                // ),
                // SizedBox(height: 20),
                // Row(
                //   children: [
                //     country != null
                //         ? Text('+${country!.phoneCode}')
                //         : Container(),
                //     SizedBox(width: 10),
                //     Expanded(
                //       child: SizedBox(
                //         width: size.width / 0.7,
                //         child: TextField(
                //           controller: phoneController,
                //           decoration: InputDecoration(
                //             hintText: 'Phone number',
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
                TextFormField(
                  controller: emailController,
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
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showSnackBar(context, 'Please enter your password');
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height / 2),
                SizedBox(
                  width: size.width / 1.2,
                  child: CustomButton(
                    onPressed: logIn,
                    text: 'LOG IN',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, SignUpScreen.routeName);
                  },
                  child: Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
