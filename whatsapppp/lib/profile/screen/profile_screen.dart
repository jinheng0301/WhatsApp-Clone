import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  static const String routeName = '/profile-screen';
  const ProfileScreen({super.key});

  final int numOfShortVideos = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ref.watch(userDataAuthProvider).when(
            loading: () => Loader(),
            error: (err, stackTrace) {
              return ErrorScreen(error: err.toString());
            },
            data: (user) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user?.profilePic ?? '',
                          placeholder: (context, url) => const Loader(),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error,
                            size: 50,
                          ),
                          fit: BoxFit.cover,
                          height: 100,
                          width: 100,
                        ),
                      ),
                      SizedBox(height: 20),
                      Column(
                        children: [
                          Text(
                            user?.name ?? 'No Name',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? 'NO email available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            user?.phoneNumber ?? 'No phone number',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 15),
                      Column(
                        children: [
                          Text(
                            numOfShortVideos.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Short videos launched',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                        height: 40,
                      ),

                      // VIDEO LISTS
                      // GridView.builder(
                      //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      //     crossAxisCount: 3,
                      //     childAspectRatio: 1,
                      //     crossAxisSpacing: 5,
                      //   ),
                      //   itemBuilder: (context, index) {
                      //     return Container();
                      //   },
                      // ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
