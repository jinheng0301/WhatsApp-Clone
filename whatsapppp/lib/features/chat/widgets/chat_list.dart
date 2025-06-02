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
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Cache for user data to avoid repeated Firestore calls
  final Map<String, Map<String, String>> _userDataCache = {};

  // Cache for group member counts
  final Map<String, int> _groupMemberCountCache = {};

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

  // Method to get user data with caching
  Future<Map<String, String>> _getUserData(String userId) async {
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final userInfo = {
          'name': userData['name'] ?? 'Unknown User',
          'profilePic': userData['profilePic'] ?? '',
        };
        _userDataCache[userId] = userInfo.cast<String, String>();
        return userInfo.cast<String, String>();
      }
    } catch (e) {
      print('Error fetching user data for $userId: $e');
    }

    // Return default values if user data couldn't be fetched
    final defaultInfo = {'name': 'Unknown User', 'profilePic': ''};
    _userDataCache[userId] = defaultInfo;
    return defaultInfo;
  }

  // Helper method to get seen status for group messages
  bool _getGroupMessageSeenStatus(dynamic messageData) {
    if (!widget.isGroupChat) return messageData.isSeen;

    // For group messages, you might want to show as "seen" if at least one person saw it
    // or implement your own logic based on requirements
    final messageMap = messageData.toMap();
    final seenBy = messageMap['seenBy'] as Map<String, dynamic>?;

    if (seenBy == null) return false;

    // Return true if anyone has seen the message (excluding sender)
    return seenBy.keys
        .where((userId) => userId != messageData.senderId)
        .isNotEmpty;
  }

  // Helper method to get seen count for group messages
  int _getGroupMessageSeenCount(dynamic messageData) {
    if (!widget.isGroupChat) return 0;

    final messageMap = messageData.toMap();
    final seenBy = messageMap['seenBy'] as Map<String, dynamic>?;

    if (seenBy == null) return 0;

    // Count users who have seen the message (excluding sender)
    return seenBy.keys.where((userId) => userId != messageData.senderId).length;
  }

  // Helper method to get list of users who have seen the message
  List<String> _getSeenByUsers(dynamic messageData) {
    if (!widget.isGroupChat) return [];

    final messageMap = messageData.toMap();
    final seenBy = messageMap['seenBy'] as Map<String, dynamic>?;

    if (seenBy == null) return [];

    return seenBy.keys
        .where((userId) => userId != messageData.senderId)
        .toList();
  }

  // Method to get group member count with caching
  Future<int> _getGroupMemberCount(String groupId) async {
    if (_groupMemberCountCache.containsKey(groupId)) {
      return _groupMemberCountCache[groupId]!;
    }

    try {
      final memberCount =
          await ref.read(chatControllerProvider).getGroupMemberCount(groupId);

      _groupMemberCountCache[groupId] = memberCount;
      return memberCount;
    } catch (e) {
      print('Error getting member count for group $groupId: $e');
      return 0;
    }
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
            _scrollToBottomInstantly();
            _isInitialLoad = false;
            _previousMessageCount = currentMessageCount;
          } else if (currentMessageCount > _previousMessageCount) {
            _scrollToBottom();
            _previousMessageCount = currentMessageCount;
          }
        });

        return ListView.builder(
          controller: messageController,
          itemCount: messages.length,
          padding: const EdgeInsets.only(bottom: 20),
          itemBuilder: (context, index) {
            final messageData = messages[index];
            var timeSent = DateFormat.Hm().format(messageData.timeSent);
            final currentUserId = FirebaseAuth.instance.currentUser!.uid;

            // Mark message as seen if needed
            if (!messageData.isSeen &&
                messageData.recieverid == currentUserId) {
              ref.read(chatControllerProvider).setChatMessageSeen(
                    context,
                    widget.receiverUserId,
                    messageData.messageId,
                    widget.isGroupChat, // Pass the isGroup
                  );
            }

            // Check if message is sent by current user
            if (messageData.senderId == currentUserId) {
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

            bool shouldMarkAsSeen = false;

            if (widget.isGroupChat) {
              if (messageData.senderId != currentUserId) {
                final messageMap = messageData.toMap();
                final seenBy = messageMap['seenBy'] as Map<String, dynamic>?;

                if (seenBy == null || !seenBy.containsKey(currentUserId)) {
                  shouldMarkAsSeen = true;
                }
              }
            } else {
              if (!messageData.isSeen &&
                  messageData.recieverid == currentUserId) {
                shouldMarkAsSeen = true;
              }
            }

            if (shouldMarkAsSeen) {
              ref.read(chatControllerProvider).setChatMessageSeen(
                    context,
                    widget.receiverUserId,
                    messageData.messageId,
                    widget.isGroupChat, // Pass the isGroupChat parameter
                  );
            }

            // Check if message is sent by current user

            if (messageData.senderId == currentUserId) {
              if (widget.isGroupChat) {
                return FutureBuilder<int>(
                  future: _getGroupMemberCount(widget.receiverUserId),
                  builder: (context, memberCountSnapshot) {
                    final totalMembers = memberCountSnapshot.data ?? 0;

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
                      isSeen: _getGroupMessageSeenStatus(messageData),
                      isGroupChat: true,
                      seenCount: _getGroupMessageSeenCount(messageData),
                      totalMembers: totalMembers,
                      seenByUsers: _getSeenByUsers(messageData),
                    );
                  },
                );
              } else {
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
                  isGroupChat: false,
                );
              }
            }
            
            // Message from other user - need to show sender info for group chats
            if (widget.isGroupChat) {
              return FutureBuilder<Map<String, String>>(
                future: _getUserData(messageData.senderId),
                builder: (context, userSnapshot) {
                  final senderName = userSnapshot.data?['name'] ?? 'Loading...';
                  final senderProfilePic =
                      userSnapshot.data?['profilePic'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: SenderMessageCard(
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
                      // Group chat specific parameters
                      isGroupChat: true,
                      senderName: senderName,
                      senderProfilePic: senderProfilePic,
                    ),
                  );
                },
              );
            } else {
              // Individual chat - no need for sender info
              return FutureBuilder<Map<String, String>>(
                future: _getUserData(messageData.senderId),
                builder: (context, snapshot) {
                  final senderProfilePic = snapshot.data?['profilePic'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: SenderMessageCard(
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
                      isGroupChat: false,
                      senderProfilePic: senderProfilePic,
                    ),
                  );
                },
              );
            }
          },
        );
      },
    );
  }
}
