import 'package:flutter/material.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/features/auth/screens/login_screen.dart';
import 'package:whatsapppp/features/auth/screens/otp_screen.dart';
import 'package:whatsapppp/features/landing/screens/landing_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (_) => LandingScreen(),
      );
    case LoginScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => LoginScreen(),
      );
    case OTPScreen.routeName:
    final verificationId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => OTPScreen(
          verificationId: verificationId,
        ),
      );
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: ErrorScreen(error: 'This page doesn\'t exist.'),
        ),
      );
  }
}
