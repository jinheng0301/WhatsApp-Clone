import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/common/providers/message_reply_provider.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/chat/controller/chat_controller.dart';
import 'package:whatsapppp/features/chat/widgets/my_message_card.dart';
import 'package:whatsapppp/features/chat/widgets/sender_message_card.dart';
import 'package:whatsapppp/models/user_model.dart';

class ChatList extends ConsumerStatefulWidget {
  late final String receiverUserId;
  late final bool isGroupChat;

  ChatList({
    required this.receiverUserId,
    required this.isGroupChat,
  });

  @override
  ConsumerState<ChatList> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController messageController = ScrollController();
  bool _isInitialLoad = true;
  int _previousMessageCount = 0;

  @override
  void dispose() {
    super.dispose();
    messageController.dispose();
  }

  void onMessageSwipe(
    String message,
    bool isMe,
    MessageEnum messageEnum,
  ) {
    ref.read(messageReplyProvider.notifier).update(
          (state) => MessageReply(
            message,
            isMe,
            messageEnum,
          ),
        );
  }

  void _scrollToBottom() {
    if (messageController.hasClients) {
      // Use animateTo instead of jumpTo for smoother scrolling
      messageController.animateTo(
        messageController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomInstantly() {
    if (messageController.hasClients) {
      messageController.jumpTo(messageController.position.maxScrollExtent);
    }
  }

  Future<String?> _getSenderProfilePic(String senderId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = UserModel.fromMap(userDoc.data()!);
        return userData.profilePic;
      }
    } catch (e) {
      print('Error getting sender profile pic: $e');
    }
    return null;
  }

  Future<String?> _getSenderName(String senderId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = UserModel.fromMap(userDoc.data()!);
        return userData.name;
      }
    } catch (e) {
      print('Error getting sender name: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.isGroupChat
          ? ref
              .read(chatControllerProvider)
              .groupChatStream(widget.receiverUserId)
          : ref.read(chatControllerProvider).chatStream(widget.receiverUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loader();
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No messages yet. Start the conversation!'),
          );
        }

        final messages = snapshot.data!;
        final currentMessageCount = messages.length;

        // Handle scrolling after the widget is built
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_isInitialLoad) {
            // First time loading - scroll to bottom instantly
            _scrollToBottomInstantly();
            _isInitialLoad = false;
            _previousMessageCount = currentMessageCount;
          } else if (currentMessageCount > _previousMessageCount) {
            // New messages arrived - scroll to bottom with animation
            _scrollToBottom();
            _previousMessageCount = currentMessageCount;
          }
        });

        return ListView.builder(
          controller: messageController,
          itemCount: messages.length,
          // Add some padding at the bottom
          padding: const EdgeInsets.only(bottom: 20),
          itemBuilder: (context, index) {
            final messageData = messages[index];
            var timeSent = DateFormat.Hm().format(messageData.timeSent);

            // Check if the message is sent by the current user
            // and if it hasn't been seen yet
            // If the message is not seen and the receiver is the current user,
            // mark it as seen
            if (!messageData.isSeen &&
                messageData.recieverid ==
                    FirebaseAuth.instance.currentUser!.uid) {
              ref.read(chatControllerProvider).setChatMessageSeen(
                    context,
                    widget.receiverUserId,
                    messageData.messageId,
                  );
            }

            // Check if the message is sent by the current user
            if (messageData.senderId ==
                FirebaseAuth.instance.currentUser!.uid) {
              return MyMessageCard(
                message: messageData.text,
                date: timeSent,
                type: messageData.type,
                repliedText: messageData.repliedMessage,
                username: messageData.repliedTo,
                repliedMessageType: messageData.repliedMessageType,
                onLeftSwipe: (details) => onMessageSwipe(
                  messageData.text,
                  true,
                  messageData.type,
                ),
                isSeen: messageData.isSeen,
              );
            }

            // If the message is not sent by the current user, it's from the other user
            if (widget.isGroupChat) {
              return FutureBuilder(
                future: Future.wait([
                  _getSenderProfilePic(messageData.senderId),
                  _getSenderName(messageData.senderId),
                ]),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  String? profilePic;
                  String? senderName;
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    profilePic = snapshot.data![0] as String?;
                    senderName = snapshot.data![1] as String?;
                  }
                  return SenderMessageCard(
                    message: messageData.text,
                    date: timeSent,
                    type: messageData.type,
                    username: messageData.repliedTo,
                    repliedMessageType: messageData.repliedMessageType,
                    onRightSwipe: (details) => onMessageSwipe(
                      messageData.text,
                      false,
                      messageData.type,
                    ),
                    repliedText: messageData.repliedMessage,
                    isGroupChat: widget.isGroupChat,
                    senderProfilePic: profilePic,
                    senderName: senderName,
                  );
                },
              );
            } else {
              return SenderMessageCard(
                message: messageData.text,
                date: timeSent,
                type: messageData.type,
                username: messageData.repliedTo,
                repliedMessageType: messageData.repliedMessageType,
                onRightSwipe: (details) => onMessageSwipe(
                  messageData.text,
                  false,
                  messageData.type,
                ),
                repliedText: messageData.repliedMessage,
                isGroupChat: widget.isGroupChat,
                senderProfilePic: null,
                senderName: null,
              );
            }
          },
        );
      },
    );
  }
}
