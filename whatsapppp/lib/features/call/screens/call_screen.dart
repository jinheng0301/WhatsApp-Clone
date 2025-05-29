// import 'package:agora_uikit/agora_uikit.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:whatsapppp/common/widgets/loader.dart';
// import 'package:whatsapppp/config/agora_config.dart';
// import 'package:whatsapppp/features/call/controller/call_controller.dart';
// import 'package:whatsapppp/models/call.dart';

// class CallScreen extends ConsumerStatefulWidget {
//   static const String routeName = '/call-screen';

//   final String channelId;
//   final bool isGroupChat;
//   final Call call;

//   CallScreen({
//     required this.channelId,
//     required this.call,
//     required this.isGroupChat,
//   });

//   @override
//   ConsumerState<CallScreen> createState() => _CallScreenState();
// }

// class _CallScreenState extends ConsumerState<CallScreen> {
//   AgoraClient? client;
//   String baseUrl = '';

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     client = AgoraClient(
//       agoraConnectionData: AgoraConnectionData(
//         appId: AgoraConfig.appId,
//         channelName: widget.channelId,
//         tokenUrl: baseUrl,
//       ),
//     );
//     initAgora();
//   }

//   void initAgora() async {
//     await client!.initialize();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: client == null
//           ? Loader()
//           : SafeArea(
//               child: Stack(
//                 children: [
//                   AgoraVideoViewer(client: client!),
//                   AgoraVideoButtons(
//                     client: client!,
//                     disconnectButtonChild: IconButton(
//                       onPressed: () async {
//                         await client!.engine.leaveChannel();
//                         ref.read(callControllerProvider).endCall(
//                               widget.call.callerId,
//                               widget.call.receiverId,
//                               context,
//                             );
//                         Navigator.pop(context);
//                       },
//                       icon: Icon(Icons.call_end),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
