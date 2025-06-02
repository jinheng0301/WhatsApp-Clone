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
  // New parameters for group chat
  late final bool isGroupChat;
  late final String senderName;
  late final String senderProfilePic;

  SenderMessageCard({
    required this.message,
    required this.date,
    required this.type,
    this.onRightSwipe,
    required this.repliedText,
    required this.username,
    required this.repliedMessageType,
    // New required parameters for group chat
    this.isGroupChat = false,
    this.senderName = '',
    this.senderProfilePic = '',
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

    int hash = name.hashCode;
    int index = hash.abs() % colors.length;
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
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 3.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width *
                  0.75, // Reduced from width - 45 to 75% of screen width
              minWidth: 120, // Added minimum width
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // always show profile picture in group chats and individual chats
                Container(
                  margin: const EdgeInsets.only(right: 6.0, bottom: 8.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: senderProfilePic.isNotEmpty
                        ? NetworkImage(senderProfilePic)
                        : null,
                    backgroundColor: Colors.grey[400],
                    child: senderProfilePic.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 22,
                            color: Colors.grey[700],
                          )
                        : null,
                  ),
                ),

                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: senderMessageColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: type == MessageEnum.text
                              ? const EdgeInsets.fromLTRB(14, 8, 50, 20)
                              : const EdgeInsets.fromLTRB(8, 6, 8, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // always show sender name if not empty
                              if (senderName.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    senderName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _getRandomColor(senderName),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                              if (isReplying) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: backgroundColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: _getRandomColor(username),
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: _getRandomColor(username),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      DisplayTextImageGif(
                                        message: repliedText,
                                        type: repliedMessageType,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              DisplayTextImageGif(
                                message: message,
                                type: type,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              date,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
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
