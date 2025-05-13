import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/landing/screens/landing_screen.dart';
import 'package:whatsapppp/firebase_options.dart';
import 'package:whatsapppp/router.dart';
import 'package:whatsapppp/screens/mobile_screen_layout.dart';

// create a StreamProvider for auth state changes
final authStateprovider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

void enableAuthPersistence() async {
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    debugPrint("Error enabling auth persistence: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  enableAuthPersistence();

  runApp(
    const ProviderScope(child: MyApp()),
    // provider scope is widget provided by riverpod
    // keep track or consists state of the application
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          color: appBarColor,
        ),
      ),
      onGenerateRoute: (settings) => onGenerateRoute(settings),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          } else if (snapshot.hasError) {
            return ErrorScreen(error: snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const LandingScreen();
          } else {
            return FutureBuilder(
              future: getUserData(snapshot.data!), // Fetch user data
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Loader();
                } else if (userSnapshot.hasError) {
                  return ErrorScreen(error: userSnapshot.error.toString());
                } else if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return const LandingScreen();
                }
                return const MobileLayoutScreen();
              },
            );
          }
        },
      ),
    );
  }

  Future<dynamic> getUserData(User user) async {
    // Fetch user data from Firestore or another source
    return null; // Replace with actual fetching logic
  }
}
