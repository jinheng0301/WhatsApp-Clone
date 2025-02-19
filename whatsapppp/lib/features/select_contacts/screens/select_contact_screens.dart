import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/select_contacts/controllers/select_contact_controller.dart';

class SelectContactScreens extends ConsumerWidget {
  static const String routeName = '/select-contact';
  const SelectContactScreens({super.key});

  void selectContact(
    WidgetRef ref,
    Contact selectedContact,
    BuildContext context,
  ) {
    ref
        .read(selectContactControllerProvider)
        .selectContact(selectedContact, context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Contact'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: ref.watch(getContactsProvider).when(
            data: (contactList) => ListView.builder(
              itemCount: contactList.length,
              itemBuilder: (context, index) {
                final contact = contactList[index];

                return GestureDetector(
                  onTap: () {
                    selectContact(ref, contact, context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: contact.photo == null
                          ? null
                          : CircleAvatar(
                              // photo wont be null
                              backgroundImage: MemoryImage(contact.photo!),
                              radius: 30,
                            ),
                      title: Text(
                        contact.displayName,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                );
              },
            ),
            error: (error, stackTrace) => ErrorScreen(
              error: error.toString(),
            ),
            loading: () => Loader(),
          ),
    );
  }
}
