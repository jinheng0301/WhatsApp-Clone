import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/properties/name.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/features/group/screens/create_group_screen.dart';
import 'package:whatsapppp/features/select_contacts/controllers/select_contact_controller.dart';
import 'package:whatsapppp/models/user_model.dart'; // Make sure to import UserModel

class SelectContactsGroup extends ConsumerStatefulWidget {
  const SelectContactsGroup({super.key});

  @override
  ConsumerState<SelectContactsGroup> createState() =>
      _SelectContactsGroupState();
}

class _SelectContactsGroupState extends ConsumerState<SelectContactsGroup> {
  List<int> selectedContactsIndex = [];

  void selectContact(int index, UserModel userModel) {
    if (selectedContactsIndex.contains(index)) {
      selectedContactsIndex.remove(index);
    } else {
      selectedContactsIndex.add(index);
    }
    setState(() {});

    // Convert UserModel to Contact format for compatibility
    final contact = Contact(
      id: userModel.uid,
      name: Name(first: userModel.name),
      phones: [Phone(userModel.phoneNumber)],
    );

    final currentContacts = ref.read(selectedGroupContacts);
    if (selectedContactsIndex.contains(index)) {
      // Add contact to selected list
      ref.read(selectedGroupContacts.notifier).state = [
        ...currentContacts,
        contact
      ];
    } else {
      // Remove contact from selected list
      ref.read(selectedGroupContacts.notifier).state =
          currentContacts.where((c) => c.id != userModel.uid).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(getRegisteredUsersProvider).when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stackTrace) => ErrorScreen(error: err.toString()),
          data: (contactList) => Expanded(
            child: ListView.builder(
                itemCount: contactList.length,
                itemBuilder: (context, index) {
                  final userModel = contactList[index];
                  return InkWell(
                    onTap: () => selectContact(index, userModel),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          userModel.name,
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        leading: selectedContactsIndex.contains(index)
                            ? IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.done),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
          ),
        );
  }
}
