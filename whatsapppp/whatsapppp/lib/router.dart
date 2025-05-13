import 'package:flutter/material.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/features/auth/screens/login_screen.dart';
import 'package:whatsapppp/features/auth/screens/sign_up_screen.dart';
import 'package:whatsapppp/features/auth/screens/user_information_screen.dart';
import 'package:whatsapppp/features/chat/screens/mobile_chat_screen.dart';
import 'package:whatsapppp/features/landing/screens/landing_screen.dart';
import 'package:whatsapppp/features/select_contacts/screens/select_contact_screens.dart';

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

    // sign up screen
    case SignUpScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => SignUpScreen(),
      );

    // // otp screen
    // case OTPScreen.routeName:
    //   final verificationId = settings.arguments as String;
    //   return MaterialPageRoute(
    //     builder: (_) => OTPScreen(
    //       verificationId: verificationId,
    //     ),
    //   );

    // user information screen
    case UserInformationScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => UserInformationScreen(),
      );

    // select contact screen
    case SelectContactScreens.routeName:
      return MaterialPageRoute(
        builder: (_) => SelectContactScreens(),
      );

    // mobile chat screen
    case MobileChatScreen.routeName:
      final arguments = settings.arguments as Map<String, dynamic>;
      final name = arguments['name'];
      final uid = arguments['uid'];
      return MaterialPageRoute(
        builder: (_) => MobileChatScreen(
          name: name,
          uid: uid,
          isGroupChat: true,
        ),
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
