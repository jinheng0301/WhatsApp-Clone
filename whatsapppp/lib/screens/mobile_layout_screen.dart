import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/chat/widgets/contacts_list.dart';
import 'package:whatsapppp/features/multimedia_editing/screens/multimedia_editing_screen.dart';
import 'package:whatsapppp/features/select_contacts/screens/select_contact_screens.dart';
import 'package:whatsapppp/features/status/screens/confirm_status_screen.dart';
import 'package:whatsapppp/features/status/screens/status_contacts_screen.dart';
import 'package:whatsapppp/profile/screen/profile_screen.dart';

class MobileLayoutScreen extends ConsumerStatefulWidget {
  const MobileLayoutScreen({super.key});

  @override
  ConsumerState<MobileLayoutScreen> createState() => _MobileLayoutScreenState();
}

class _MobileLayoutScreenState extends ConsumerState<MobileLayoutScreen> {
  late PageController pageController;
  int _page = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    pageController.dispose();
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  Future<void> _showDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Call the sign-out method from the AuthController
                  await ref
                      .read(authControllerProvider)
                      .signOut(context: context);
                } catch (e) {
                  showSnackBar(context, 'Failed to sign out: $e');
                }
              },
              child: Text('Conlan7firm!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarColor,
        centerTitle: false,
        title: Text(
          'WhatsApp',
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.search,
              color: Colors.grey,
            ),
          ),
          PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.grey,
            ),
            onSelected: (value) {
              if (value == ' create_group') {
                Navigator.pushNamed(context, '/create-group');
              } else if (value == 'add_status') {
                Navigator.pushNamed(context, '/add-status');
              } else if (value == 'logout') {
                // show log out dialog
                _showDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              switch (_page) {
                case 0:
                  return [
                    const PopupMenuItem<String>(
                      value: 'create_group',
                      child: Text('Create Group'),
                    ),
                  ];

                case 1:
                  return [
                    const PopupMenuItem<String>(
                      value: 'add_status',
                      child: Text('Add Status'),
                    ),
                  ];

                case 3:
                  return [
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Log out'),
                    ),
                  ];

                default:
                  return [];
              }
            },
          )
        ],
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          ContactsList(),
          StatusContactsScreen(),
          MultimediaEditingScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        child: CupertinoTabBar(
          onTap: navigationTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.chat_bubble_rounded,
                size: 30,
                color: _page == 0 ? primaryColor : secondaryColor,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.update_sharp,
                size: 30,
                color: _page == 1 ? primaryColor : secondaryColor,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.tiktok_outlined,
                size: 30,
                color: _page == 2 ? primaryColor : secondaryColor,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Consumer(
                builder: (context, ref, _) {
                  final userAsync = ref.watch(userDataAuthProvider);
                  return userAsync.when(
                    data: (user) {
                      if (user == null) {
                        return Icon(
                          Icons.person,
                          size: 30,
                          color: _page == 3 ? primaryColor : secondaryColor,
                        );
                      } else {
                        return CircleAvatar(
                          radius: 15,
                          backgroundImage: NetworkImage(user.profilePic),
                        );
                      }
                    },
                    loading: () => const Loader(),
                    error: (err, stack) => const Icon(
                      Icons.error,
                      size: 30,
                      color: Colors.red,
                    ),
                  );
                },
              ),
              label: '',
            ),
          ],
        ),
      ),
      floatingActionButton: () {
        switch (_page) {
          case 0:
            return FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, SelectContactScreens.routeName);
              },
              backgroundColor: tabColor,
              child: Icon(Icons.comment, size: 30, color: Colors.white),
            );
          case 1:
            return FloatingActionButton(
              onPressed: () async {
                File? pickedImage = await pickImageFromGallery(context);
                if (pickedImage != null) {
                  Navigator.pushNamed(
                    context,
                    ConfirmStatusScreen.routeName,
                    arguments: pickedImage,
                  );
                }
              },
              backgroundColor: tabColor,
              child: Icon(Icons.camera_alt, size: 30, color: Colors.white),
            );
          case 2:
            return FloatingActionButton(
              onPressed: () async {
                File? pickedImage = await pickImageFromGallery(context);
                if (pickedImage != null) {
                  Navigator.pushNamed(
                    context,
                    ConfirmStatusScreen.routeName,
                    arguments: pickedImage,
                  );
                }
              },
              backgroundColor: tabColor,
              child: Icon(Icons.edit, size: 30, color: Colors.white),
            );
          default:
            return null;
        }
      }(),
    );
  }
}
