import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login-screen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  Country? country;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    phoneController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Enter your phone number'),
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'WhatsApp will send an SMS message to verify your phone number.',
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => pickCountry(),
              child: Text('Pick a country'),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                country != null ? Text('+${country!.phoneCode}') : Container(),
                SizedBox(width: 10),
                SizedBox(
                  width: size.width / 0.7,
                  child: TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.6),
            SizedBox(
              width: 90,
              child: CustomButton(
                onPressed: () {},
                text: 'NEXT',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
