import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/chat/widgets/contacts_list.dart';
import 'package:whatsapppp/features/select_contacts/screens/select_contact_screens.dart';
import 'package:whatsapppp/features/status/screens/confirm_status_screen.dart';
import 'package:whatsapppp/features/status/screens/status_contacts_screen.dart';

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
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Text('Create Group'),
                onTap: () => Future(
                  () => Navigator.pushNamed(context, '/create-group'),
                ),
              )
            ],
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
          Center(
            child: Text('Calls'),
          ),
          Center(
            child: Text('Profile'),
          ),
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
                Icons.call,
                size: 30,
                color: _page == 2 ? primaryColor : secondaryColor,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: 30,
                color: _page == 3 ? primaryColor : secondaryColor,
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
          default:
            return null;
        }
      }(),
    );
  }
}
