import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/chat/controller/chat_controller.dart';
import 'package:whatsapppp/features/chat/screens/mobile_chat_screen.dart';

class ContactsList extends ConsumerWidget {
  const ContactsList({super.key});

  /// Formats the time display for WhatsApp-like experience
  String _formatTime(DateTime timeSent) {
    final now = DateTime.now();
    final difference = now.difference(timeSent);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat.Hm().format(timeSent);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat.E().format(timeSent);
    } else {
      // Older - show date
      return DateFormat.MMMd().format(timeSent);
    }
  }

  /// Builds unread message count badge with improved styling and debug info
  Widget _buildUnreadBadge(int unreadCount, {String? debugName}) {
    // Debug print to track badge creation
    if (debugName != null) {
      print('_buildUnreadBadge for $debugName: count = $unreadCount');
    }

    if (unreadCount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Enhanced chat item builder with better debugging
  Widget _buildChatItem({
    required BuildContext context,
    required String name,
    required String lastMessage,
    required DateTime timeSent,
    required String profilePic,
    required String id,
    required bool isGroupChat,
    required int unreadCount,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profilePic),
        radius: 24,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: unreadCount > 0 ? Colors.black87 : Colors.grey,
            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
      trailing: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(timeSent),
              style: TextStyle(
                color: unreadCount > 0 ? primaryColor : Colors.grey,
                fontSize: 12,
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            // Pass debug name to badge
            _buildUnreadBadge(unreadCount, debugName: name),
          ],
        ),
      ),
      onTap: () => Navigator.pushNamed(
        context,
        MobileChatScreen.routeName,
        arguments: {
          'name': name,
          'uid': id,
          'isGroupChat': isGroupChat,
          'profilePic': profilePic,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────── GROUPS ───────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Groups',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Consumer(builder: (context, ref, _) {
            final groupStream = ref.watch(chatControllerProvider).chatGroups();
            return StreamBuilder(
              stream: groupStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Loader();
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading groups'));
                } else if (!snapshot.hasData ||
                    (snapshot.data?.isEmpty ?? true)) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No groups yet.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                final groups = snapshot.data!;

                // Sort groups by latest message time (most recent first)
                groups.sort((a, b) => b.timeSent.compareTo(a.timeSent));

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: dividerColor,
                    indent: 85,
                  ),
                  itemBuilder: (context, i) {
                    final grp = groups[i];

                    return _buildChatItem(
                      context: context,
                      name: grp.name,
                      lastMessage: grp.lastMessage,
                      timeSent: grp.timeSent,
                      profilePic: grp.groupPic,
                      id: grp.groupId,
                      isGroupChat: true,
                      unreadCount: grp.unreadCount,
                    );
                  },
                );
              },
            );
          }),

          const SizedBox(height: 24),

          // ─────────── CONTACTS ───────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Contacts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Consumer(builder: (context, ref, _) {
            final contactStream =
                ref.watch(chatControllerProvider).chatContacts();
            return StreamBuilder(
              stream: contactStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Loader();
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading contacts',
                    ),
                  );
                } else if (!snapshot.hasData ||
                    (snapshot.data?.isEmpty ?? true)) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No contacts yet.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                final contacts = snapshot.data!;

                // Sort contacts by latest message time (most recent first)
                contacts.sort((a, b) => b.timeSent.compareTo(a.timeSent));

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: dividerColor,
                    indent: 85,
                  ),
                  itemBuilder: (context, i) {
                    final c = contacts[i];

                    return _buildChatItem(
                      context: context,
                      name: c.name,
                      lastMessage: c.lastMessage,
                      timeSent: c.timeSent,
                      profilePic: c.profilePic,
                      id: c.contactId,
                      isGroupChat: false,
                      unreadCount: c.unreadCount,
                    );
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
