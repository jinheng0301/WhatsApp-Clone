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

  // Helper method to create a test contact for development purposes
  Contact _createTestContact(String name, String phone) {
    final contact = Contact();
    contact.displayName = name;
    contact.phones = [Phone(phone)];
    return contact;
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
      body: Column(
        children: [
          // Add a development mode banner and test contacts option
          Container(
            color: Colors.amber.withOpacity(0.3),
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(Icons.developer_mode, color: Colors.amber[800]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Development Mode: Use test contacts for emulator testing',
                    style: TextStyle(color: Colors.amber[800]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // This is where you would inject test contacts for development
                    // For now we'll just show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Test contacts enabled')),
                    );
                  },
                  child: Text('USE TEST CONTACTS'),
                ),
              ],
            ),
          ),

          // Test contacts section - Visible only in development mode
          Container(
            color: Colors.grey.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Test Contacts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Sample test contacts for emulator testing
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text('T'),
                  ),
                  title: Text('Test User 1'),
                  subtitle: Text('+1234567890'),
                  onTap: () {
                    // Create and select a test contact
                    final testContact =
                        _createTestContact('Test User 1', '+1234567890');
                    selectContact(ref, testContact, context);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text('T'),
                  ),
                  title: Text('Test User 2'),
                  subtitle: Text('+9876543210'),
                  onTap: () {
                    // Create and select a test contact
                    final testContact =
                        _createTestContact('Test User 2', '+9876543210');
                    selectContact(ref, testContact, context);
                  },
                ),
                Divider(),
              ],
            ),
          ),

          // Real contacts section
          Expanded(
            child: ref.watch(getContactsProvider).when(
                  data: (contactList) => contactList.isEmpty
                      ? Center(
                          child: Text(
                              'No contacts found. Register some test users first.'),
                        )
                      : ListView.builder(
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
                                      ? CircleAvatar(
                                          child: Text(
                                            contact.displayName[0]
                                                .toUpperCase(),
                                          ),
                                        )
                                      : CircleAvatar(
                                          backgroundImage:
                                              MemoryImage(contact.photo!),
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
          ),
        ],
      ),
    );
  }
}
