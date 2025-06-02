import 'package:flutter/material.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/features/chat/widgets/display_text_image_gif.dart';

class MyMessageCard extends StatelessWidget {
  late final String message;
  late final String date;
  late final MessageEnum type;
  late final MessageEnum repliedMessageType;
  late final GestureDragUpdateCallback? onLeftSwipe;
  late final String repliedText;
  late final String username;
  late final bool isSeen;
  // New parameters for group chat seen status
  late final bool isGroupChat;
  late final int? seenCount;
  late final int? totalMembers;
  late final List<String>? seenByUsers;

  MyMessageCard({
    required this.message,
    required this.date,
    required this.type,
    required this.repliedMessageType,
    this.onLeftSwipe,
    required this.repliedText,
    required this.username,
    required this.isSeen,
    // New optional parameters for group chat
    this.isGroupChat = false,
    this.seenCount,
    this.totalMembers,
    this.seenByUsers,
  });

  // Helper method to get seen status icon and color
  Widget _buildSeenStatusIcon() {
    if (isGroupChat) {
      // Group chat seen status logic
      if (seenCount == null || seenCount == 0) {
        // Message not seen by anyone
        return Icon(
          Icons.done,
          size: 16,
          color: Colors.white60,
        );
      } else if (totalMembers != null && seenCount! >= (totalMembers! - 1)) {
        // Message seen by all members (excluding sender)
        return Icon(
          Icons.done_all,
          size: 16,
          color: Colors.blue,
        );
      } else {
        // Message seen by some members
        return Icon(
          Icons.done_all,
          size: 16,
          color: Colors.white60,
        );
      }
    } else {
      // Individual chat seen status logic (original logic)
      return Icon(
        isSeen ? Icons.done_all : Icons.done,
        size: 16,
        color: isSeen ? Colors.blue : Colors.white60,
      );
    }
  }

  // Helper method to get seen status text for group chats
  String _getSeenStatusText() {
    if (isGroupChat && seenCount != null) {
      if (seenCount == 0) {
        return date;
      } else if (totalMembers != null) {
        return '$date • Seen by $seenCount/${totalMembers! - 1}';
      } else {
        return '$date • Seen by $seenCount';
      }
    }
    return date;
  }

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

  // Method to show detailed seen status (optional - for long press or tap)
  void _showSeenDetails(BuildContext context) {
    if (!isGroupChat || seenByUsers == null || seenByUsers!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seen by',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...seenByUsers!.map((userId) => ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(userId),
                  trailing: Icon(Icons.done_all, color: Colors.blue),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isReplying = repliedText.isNotEmpty;

    return SwipeTo(
      onLeftSwipe: onLeftSwipe,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 3.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  width * 0.75, // 75% of screen width like SenderMessageCard
              minWidth: 120, // Added minimum width
            ),
            child: GestureDetector(
              onTap: isGroupChat ? () => _showSeenDetails(context) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: messageColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight:
                        Radius.circular(4), // Different corner for my messages
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: Offset(0, 1),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getSeenStatusText(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(width: 4),
                            _buildSeenStatusIcon(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
