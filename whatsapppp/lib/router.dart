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
      // Verify the arguments and create the screen
      if (settings.arguments is Map<String, dynamic>) {
        final Map<String, dynamic> args =
            settings.arguments as Map<String, dynamic>;

        // Log the arguments to debug
        print('Route arguments: $args');

        // Validate that all required arguments are present
        final bool isValidArgs = args.containsKey('name') &&
            args.containsKey('uid') &&
            args.containsKey('isGroupChat') &&
            args.containsKey('profilePic');

        if (isValidArgs) {
          return MaterialPageRoute(
            builder: (context) => MobileChatScreen(
              name: args['name'] as String,
              uid: args['uid'] as String,
              isGroupChat: args['isGroupChat'] as bool,
              profilePic: args['profilePic'] as String,
            ),
          );
        }
      }

      // If arguments are missing or invalid, show an error screen
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Invalid arguments for MobileChatScreen'),
          ),
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
