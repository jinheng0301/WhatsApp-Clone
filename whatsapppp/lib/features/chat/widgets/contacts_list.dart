import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/chat/controller/chat_controller.dart';
import 'package:whatsapppp/features/chat/screens/mobile_chat_screen.dart';

class ContactsList extends ConsumerWidget {
  const ContactsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────── GROUPS ───────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  return Loader();
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading groups'));
                } else if (!snapshot.hasData ||
                    (snapshot.data?.isEmpty ?? true)) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No groups yet.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                final groups = snapshot.data!;

                return ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => Divider(
                    color: dividerColor,
                    indent: 85,
                  ),
                  itemBuilder: (context, i) {
                    final grp = groups[i];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(grp.groupPic),
                        radius: 24,
                      ),
                      title: Text(grp.name),
                      subtitle: Text(
                        grp.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        DateFormat.Hm().format(grp.timeSent),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        MobileChatScreen.routeName,
                        arguments: {
                          'name': grp.name,
                          'uid': grp.groupId,
                          'isGroupChat': true,
                          'profilePic': grp.groupPic,
                        },
                      ),
                    );
                  },
                );
              },
            );
          }),

          SizedBox(height: 24),

          // ─────────── CONTACTS ───────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  return Loader();
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading contacts',
                    ),
                  );
                } else if (!snapshot.hasData ||
                    (snapshot.data?.isEmpty ?? true)) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No contacts yet.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                final contacts = snapshot.data!;

                return ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => Divider(
                    color: dividerColor,
                    indent: 85,
                  ),
                  itemBuilder: (context, i) {
                    final c = contacts[i];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(c.profilePic),
                        radius: 24,
                      ),
                      title: Text(c.name),
                      subtitle: Text(
                        c.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        DateFormat.Hm().format(c.timeSent),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        MobileChatScreen.routeName,
                        arguments: {
                          'name': c.name,
                          'uid': c.contactId,
                          'isGroupChat': false,
                          'profilePic': c.profilePic,
                        },
                      ),
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
