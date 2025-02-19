import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/landing/screens/landing_screen.dart';
import 'package:whatsapppp/firebase_options.dart';
import 'package:whatsapppp/router.dart';
import 'package:whatsapppp/screens/mobile_layout_screen.dart';

// create a StreamProvider for auth state changes
final authStateprovider = StreamProvider((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
    // provider scope is widget provided by riverpod
    // keep track or consists state of the application
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch the auth state changes
    final authState = ref.watch(authStateprovider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          color: appBarColor,
        ),
      ),
      onGenerateRoute: (settings) => onGenerateRoute(settings),
      home: authState.when(
        data: (user) {
          if (user == null) {
            return LandingScreen();
          }

          return ref.watch(userDataAuthProvider).when(
                data: (userData) {
                  if (userData == null) {
                    // Handle edge case where user auth exists but no user data
                    return const LandingScreen();
                  }
                  return const MobileLayoutScreen();
                },
                error: (error, stackTrace) {
                  return ErrorScreen(
                    error: error.toString(),
                  );
                },
                loading: () => const Loader(),
              );
        },
        error: (error, stackTrace) {
          return ErrorScreen(
            error: error.toString(),
          );
        },
        loading: () => const Loader(),
      ),
    );
  }
}
