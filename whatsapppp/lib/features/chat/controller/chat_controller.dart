import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/common/providers/message_reply_provider.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/chat/repositories/chat_repository.dart';
import 'package:whatsapppp/models/chat_contact.dart';
import 'package:whatsapppp/models/group.dart';
import 'package:whatsapppp/models/message.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);

  return ChatController(
    chatRepository: chatRepository,
    ref: ref,
  );
});

class ChatController {
  final ChatRepository chatRepository;
  final Ref ref;

  ChatController({
    required this.chatRepository,
    required this.ref,
  });

  Stream<List<ChatContact>> chatContacts() {
    return chatRepository.getChatContacts();
  }

  Stream<List<GroupChat>> chatGroups() {
    return chatRepository.getChatGroups();
  }

  Stream<List<Message>> chatStream(String recieverUserId) {
    return chatRepository.getChatStream(recieverUserId);
  }

  Stream<List<Message>> groupChatStream(String groupId) {
    return chatRepository.getGroupChatStream(groupId);
  }

  void sendTextMessage(
    BuildContext context,
    String text,
    String receiverUserId,
    bool isGroupChat,
  ) async {
    try {
      print('ChatController: Starting to send message');
      print('Text: $text');
      print('Receiver ID: $receiverUserId');
      print('Is Group Chat: $isGroupChat');

      final messageReply = ref.read(messageReplyProvider);

      // Get user data first and handle it properly
      final userDataAsync = ref.read(userDataAuthProvider);

      userDataAsync.when(
        data: (userData) {
          if (userData == null) {
            print('ChatController: User data is null');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User not authenticated')),
            );
            return;
          }

          print('ChatController: User data found: ${userData.name}');
          print('ChatController: Calling repository sendTextMessage');

          chatRepository.sendTextMessage(
            context: context,
            text: text,
            recieverUserId: receiverUserId,
            senderUser: userData,
            messageReply: messageReply,
            isGroupChat: isGroupChat,
          );
        },
        loading: () {
          print('ChatController: User data is loading');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loading user data...')),
          );
        },
        error: (error, stack) {
          print('ChatController: Error getting user data: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error.toString()}')),
          );
        },
      );

      // Clear the message reply
      ref.read(messageReplyProvider.notifier).update((state) => null);
    } catch (e) {
      print('ChatController: Exception in sendTextMessage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  void sendFileMessage(
    BuildContext context,
    File file,
    String recieverUserId,
    MessageEnum messageEnum,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userDataAuthProvider).whenData(
          (value) => chatRepository.sendFileMessage(
            context: context,
            file: file,
            recieverUserId: recieverUserId,
            senderUserData: value!,
            messageEnum: messageEnum,
            ref: ref,
            messageReply: messageReply,
            isGroupChat: isGroupChat,
          ),
        );
    ref.read(messageReplyProvider.notifier).update(
          (state) => null,
        );
  }

  void sendGIFMessage(
    BuildContext context,
    String gifUrl,
    String recieverUserId,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    int gifUrlPartIndex = gifUrl.lastIndexOf('-') + 1;
    String gifUrlPart = gifUrl.substring(gifUrlPartIndex);
    String newgifUrl = 'https://i.giphy.com/media/$gifUrlPart/200.gif';

    ref.read(userDataAuthProvider).whenData(
          (value) => chatRepository.sendGIFMessage(
            context: context,
            gifUrl: newgifUrl,
            recieverUserId: recieverUserId,
            senderUser: value!,
            messageReply: messageReply,
            isGroupChat: isGroupChat,
          ),
        );
    ref.read(messageReplyProvider.notifier).update(
          (state) => null,
        );
  }

  void setChatMessageSeen(
    BuildContext context,
    String recieverUserId,
    String messageId,
  ) {
    chatRepository.setChatMessageSeen(
      context,
      recieverUserId,
      messageId,
    );
  }
}
