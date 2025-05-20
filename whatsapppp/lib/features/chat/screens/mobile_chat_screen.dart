import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/chat/widgets/bottom_chat_field.dart';
import 'package:whatsapppp/features/chat/widgets/chat_list.dart';
import 'package:whatsapppp/models/user_model.dart';

class MobileChatScreen extends ConsumerWidget {
  static const String routeName = '/mobile-chat-screen';
  final String name;
  final String uid;
  final bool isGroupChat;
  final String profilePic;

  MobileChatScreen({
    required this.name,
    required this.uid,
    required this.isGroupChat, // Make sure this is required
    required this.profilePic, // Add profilePic parameter
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: isGroupChat
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name),
                  const Text(
                    'Group',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              )
            : StreamBuilder<UserModel>(
                stream: ref.read(authControllerProvider).userDataById(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Loader();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name),
                      Text(
                        snapshot.data?.isOnline ?? false ? 'Online' : 'Offline',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                      )
                    ],
                  );
                },
              ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.video_call),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatList(
              receiverUserId: uid,
              isGroupChat: isGroupChat,
            ),
          ),
          BottomChatField(
            receiverUserId: uid,
            isGroupChat: isGroupChat,
          ),
        ],
      ),
    );
  }

  // Factory constructor to handle route arguments
  static Widget fromRoute(BuildContext context, Object? arguments) {
    final args = arguments as Map<String, dynamic>;
    return MobileChatScreen(
      name: args['name'] as String,
      uid: args['uid'] as String,
      isGroupChat: args['isGroupChat'] as bool,
      profilePic: args['profilePic'] as String,
    );
  }
}
