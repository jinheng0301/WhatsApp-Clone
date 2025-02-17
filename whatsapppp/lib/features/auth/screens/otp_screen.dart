// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:whatsapppp/common/utils/color.dart';
// import 'package:whatsapppp/features/auth/controller/auth_controller.dart';

// class OTPScreen extends ConsumerWidget {
//   static const String routeName = '/OTP-screen';
//   final String verificationId;

//   OTPScreen({required this.verificationId});

//   void verifyOTP(BuildContext context, String userOTP, WidgetRef ref) {
//     // verify the OTP
//     ref.read(authControllerProvider).verifyOTP(
//           context: context,
//           verificationId: verificationId,
//           userOTP: userOTP,
//         );
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Verify your phone number'),
//         elevation: 0,
//         backgroundColor: backgroundColor,
//       ),
//       body: Center(
//         child: Column(
//           children: [
//             SizedBox(height: 20),
//             Text('We have sent and SMS with a code. '),
//             SizedBox(
//               width: size.width * 0.5,
//               child: TextField(
//                 textAlign: TextAlign.center,
//                 decoration: InputDecoration(
//                   hintText: '- - - - - -',
//                   hintStyle: TextStyle(fontSize: 30),
//                 ),
//                 keyboardType: TextInputType.number,
//                 onChanged: (value) {
//                   if (value.length == 6) {
//                     verifyOTP(context, value.trim(), ref);
//                   }
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
