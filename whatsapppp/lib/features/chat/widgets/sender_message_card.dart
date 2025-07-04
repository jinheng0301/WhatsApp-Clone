import 'package:flutter/material.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/features/chat/widgets/display_text_image_gif.dart';

class SenderMessageCard extends StatelessWidget {
  late final String message;
  late final String date;
  late final MessageEnum type;
  late final GestureDragUpdateCallback? onRightSwipe;
  late final String repliedText;
  late final String username;
  late final MessageEnum repliedMessageType;
  late final bool isGroupChat;
  late final String? senderProfilePic;
  late final String? senderName;

  SenderMessageCard({
    required this.message,
    required this.date,
    required this.type,
    this.onRightSwipe,
    required this.repliedText,
    required this.username,
    required this.repliedMessageType,
    this.isGroupChat = false,
    this.senderProfilePic,
    this.senderName,
  });

  // Helper method to generate consistent colors for usernames
  Color _getRandomColor(String name) {
    final colors = [
      Colors.red[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
      Colors.pink[300]!,
      Colors.indigo[300]!,
    ];

    // Use the hash code to consistently assign colors
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isReplying = repliedText.isNotEmpty;

    return SwipeTo(
      onRightSwipe: onRightSwipe,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width - 45,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Profile picture for group chats
                if (isGroupChat) ...[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        senderProfilePic != null && senderProfilePic!.isNotEmpty
                            ? NetworkImage(senderProfilePic!)
                            : null,
                    child: senderProfilePic == null || senderProfilePic!.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],

                // Message content
                Flexible(
                  child: Card(
                    color: senderMessageColor,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: type == MessageEnum.text
                              ? const EdgeInsets.only(
                                  left: 12,
                                  right: 30,
                                  top: 8,
                                  bottom: 22,
                                )
                              : const EdgeInsets.only(
                                  left: 8,
                                  top: 8,
                                  right: 8,
                                  bottom: 28,
                                ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sender name for group chats
                              if (isGroupChat && senderName != null) ...[
                                Text(
                                  senderName!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _getRandomColor(senderName!),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],

                              // Replied message section
                              if (isReplying) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: backgroundColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.white70,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      DisplayTextImageGif(
                                        message: repliedText,
                                        type: repliedMessageType,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Main message content
                              DisplayTextImageGif(
                                message: message,
                                type: type,
                              ),
                            ],
                          ),
                        ),

                        // Timestamp
                        Positioned(
                          bottom: 4,
                          right: 10,
                          child: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
