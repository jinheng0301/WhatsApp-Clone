import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/select_contacts/controllers/select_contact_controller.dart';
import 'package:whatsapppp/models/user_model.dart';

class SelectContactScreens extends ConsumerStatefulWidget {
  static const String routeName = '/select-contact';
  const SelectContactScreens({super.key});

  @override
  ConsumerState<SelectContactScreens> createState() =>
      _SelectContactScreensState();
}

class _SelectContactScreensState extends ConsumerState<SelectContactScreens>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // This method is called when the app state changes (e.g., when the app is resumed or paused)
  // It updates the user's online status in the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(authControllerProvider).setUserState(true);
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        ref.read(authControllerProvider).setUserState(false);
        break;

      default:
        ref.read(authControllerProvider).setUserState(false);
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void selectUser(UserModel selectedUser) {
    ref.read(selectContactControllerProvider).selectUser(selectedUser, context);
  }

  @override
  Widget build(BuildContext context) {
    // Use search provider if there's a search query, otherwise use all users
    final userProvider = _searchQuery.isEmpty
        ? ref.watch(getRegisteredUsersProvider)
        : ref.watch(searchUsersProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Contact'),
        actions: [
          IconButton(
            onPressed: () {
              // Toggle search functionality
              if (_searchController.text.isNotEmpty) {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              }
            },
            icon: Icon(Icons.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Development Mode Banner
          Container(
            color: Colors.blue.withOpacity(0.1),
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[800]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing all registered users in the app',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),

          // Registered Users List
          Expanded(
            child: userProvider.when(
              data: (userList) {
                if (userList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No other users registered yet'
                              : 'No users found matching "$_searchQuery"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            'Register more accounts to test chat functionality',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final user = userList[index];

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: user.profilePic.isNotEmpty
                                  ? NetworkImage(user.profilePic)
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: user.profilePic.isEmpty
                                  ? Text(
                                      user.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            // Online status indicator
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: user.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.phoneNumber,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              user.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color:
                                    user.isOnline ? Colors.green : Colors.grey,
                                fontSize: 12,
                                fontWeight: user.isOnline
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.blue,
                        ),
                        onTap: () {
                          selectUser(user);
                        },
                      ),
                    );
                  },
                );
              },
              error: (error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Error loading users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(getRegisteredUsersProvider);
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => Loader(),
            ),
          ),
        ],
      ),
    );
  }
}
