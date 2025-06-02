import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/auth/screens/login_screen.dart';
import 'package:whatsapppp/firebase_options.dart';
import 'package:whatsapppp/router.dart';
import 'package:whatsapppp/screens/mobile_layout_screen.dart';
import 'package:whatsapppp/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WhatsApp Clone',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          color: appBarColor,
        ),
      ),
      onGenerateRoute: (settings) => onGenerateRoute(settings),
      home: ref.watch(authStateProvider).when(
            data: (User? user) {
              if (user == null) {
                return LoginScreen();
              }

              return ref.watch(userDataAuthProvider).when(
                    data: (UserModel? userData) {
                      if (userData == null) {
                        return LoginScreen();
                      }

                      print(
                        '🔑 CurrentUser UID = ${FirebaseAuth.instance.currentUser?.uid}',
                      );

                      return const MobileLayoutScreen();
                    },
                    loading: () => const Loader(),
                    error: (err, trace) => ErrorScreen(
                      error: err.toString(),
                    ),
                  );
            },
            loading: () => const Loader(),
            error: (err, trace) => ErrorScreen(
              error: err.toString(),
            ),
          ),
    );
  }
}
