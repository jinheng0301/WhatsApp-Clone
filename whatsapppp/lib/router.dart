import 'package:flutter/material.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/features/auth/screens/login_screen.dart';
import 'package:whatsapppp/features/auth/screens/otp_screen.dart';
import 'package:whatsapppp/features/auth/screens/user_information_screen.dart';
import 'package:whatsapppp/features/landing/screens/landing_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (_) => LandingScreen(),
      );

    // login screen
    case LoginScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => LoginScreen(),
      );

    // otp screen
    case OTPScreen.routeName:
      final verificationId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => OTPScreen(
          verificationId: verificationId,
        ),
      );

    // user information screen
    case UserInformationScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => UserInformationScreen(),
      );

    // error screen
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: ErrorScreen(error: 'This page doesn\'t exist.'),
        ),
      );
  }
}
