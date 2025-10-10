import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/group/controller/group_controller.dart';
import 'package:whatsapppp/features/group/widget/select_contacts_group.dart';

// state provider to hold selected group contacts
final selectedGroupContacts = StateProvider<List<Contact>>((ref) => []);

class CreateGroupScreen extends ConsumerStatefulWidget {
  static const String routeName = '/create-group';
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController groupNameController = TextEditingController();
  File? image;

  void selectImage() async {
    image = await pickImageFromGallery(context);
    setState(() {});
  }

  void createGroup() {
    final groupName = groupNameController.text.trim();
    final selectedContacts = ref.read(selectedGroupContacts);

    if (groupName.isEmpty) {
      showSnackBar(context, 'Please enter a group name');
      return;
    }

    if (selectedContacts.length < 2) {
      showSnackBar(
        context,
        'Please select at least 2 contacts to create a group',
      );
      return;
    }

    // Call the createGroup method from the controller
    ref.read(groupControllerProvider).createGroup(
          context,
          groupName,
          image, // image can be null, so ensure to handle it in the controller
          selectedContacts,
        );

    ref.read(selectedGroupContacts.notifier).update((state) => []);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    groupNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedContacts = ref.watch(selectedGroupContacts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: tabColor,
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 10),
            Stack(
              children: [
                image == null
                    ? const CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://png.pngitem.com/pimgs/s/649-6490124_katie-notopoulos-katienotopoulos-i-write-about-tech-round.png',
                        ),
                        radius: 64,
                      )
                    : CircleAvatar(
                        backgroundImage: FileImage(
                          image!,
                        ),
                        radius: 64,
                      ),
                Positioned(
                  bottom: -10,
                  left: 80,
                  child: IconButton(
                    onPressed: selectImage,
                    icon: const Icon(
                      Icons.add_a_photo,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: groupNameController,
                decoration: InputDecoration(
                  hintText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(10),
              child: Text(
                'Select Contacts (${selectedContacts.length} selected, minimum 2 required)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SelectContactsGroup(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: tabColor,
        onPressed: createGroup,
        child: Icon(
          Icons.done,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
