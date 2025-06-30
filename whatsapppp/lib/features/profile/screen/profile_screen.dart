import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/multimedia_editing/repository/media_repository.dart';
import 'package:whatsapppp/features/profile/function_handler/profile_image_preview_handler.dart';
import 'package:whatsapppp/features/profile/function_handler/profile_video_preview_handler.dart';

// Provider to manage the selected tab state ('posts' or 'videos')
final selectedTabProvider = StateProvider<String>((ref) => 'posts');

// Provider for user's media files
final userMediaFilesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  final userId = mediaRepository.auth.currentUser?.uid;

  if (userId == null) {
    return Stream.value(<Map<String, dynamic>>[]);
  }

  return mediaRepository.getUserMediaFiles();
});

final userVideoFilesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  final userId = mediaRepository.auth.currentUser?.uid;

  if (userId == null) {
    return Stream.value(<Map<String, dynamic>>[]);
  }

  return mediaRepository.getMediaByType('video');
});

// Enhanced provider with better debugging
final blobImageProvider =
    FutureProvider.family<File?, String>((ref, blobId) async {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  final userId = mediaRepository.auth.currentUser?.uid;

  print('🔍 BlobImageProvider called:');
  print('   - blobId: $blobId');
  print('   - userId: $userId');

  if (userId == null) {
    print('❌ No user ID found');
    return null;
  }

  try {
    // First check if the document exists in Firestore
    final doc = await mediaRepository.firestore
        .collection('edited_images')
        .doc(blobId)
        .get();

    print('📄 Firestore document check:');
    print('   - exists: ${doc.exists}');
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      print('   - blobPath: ${data['blobPath']}');
      print('   - fileName: ${data['fileName']}');
      print('   - userId: ${data['userId']}');
      print('   - storageType: ${data['storageType']}');
    }

    final result = await mediaRepository.getMediaFileFromBlob(
      blobId: blobId,
      userId: userId,
    );

    print('📁 getMediaFileFromBlob result: ${result?.path ?? 'null'}');
    return result;
  } catch (e, stackTrace) {
    print('💥 BlobImageProvider error: $e');
    print('📚 Stack trace: $stackTrace');
    return null;
  }
});

final blobVideoProvider =
    FutureProvider.family<File?, String>((ref, blobId) async {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  final userId = mediaRepository.auth.currentUser?.uid;

  print('🔍 BlobVideoProvider called:');
  print('   - blobId: $blobId');
  print('   - userId: $userId');

  if (userId == null) {
    print('❌ No user ID found');
    return null;
  }

  try {
    // First check if the document exists in Firestore
    final doc = await mediaRepository.firestore
        .collection('edited_videos')
        .doc(blobId)
        .get();

    print('📄 Firestore document check:');
    print('   - exists: ${doc.exists}');
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      print('   - blobPath: ${data['blobPath']}');
      print('   - fileName: ${data['fileName']}');
      print('   - userId: ${data['userId']}');
      print('   - storageType: ${data['storageType']}');
    }

    final result = await mediaRepository.getMediaFileFromBlob(
      blobId: blobId,
      userId: userId,
    );

    print('📁 getMediaFileFromBlob result: ${result?.path ?? 'null'}');
    return result;
  } catch (e, stackTrace) {
    print('💥 BlobVideoProvider error: $e');
    print('📚 Stack trace: $stackTrace');
    return null;
  }
});

class ProfileScreen extends ConsumerStatefulWidget {
  static const String routeName = '/profile-screen';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

  Widget _buildStatsSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Image counts
            ref.watch(userMediaFilesProvider).when(
                  loading: () => const Text('Loading images...'),
                  error: (err, stackTrace) =>
                      const Text('Error loading images'),
                  data: (mediaFiles) {
                    return Column(
                      children: [
                        Text(
                          mediaFiles.length.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Edited Images',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  },
                ),

            // Videos count
            ref.watch(userVideoFilesProvider).when(
                  loading: () => const Text('Loading videos...'),
                  error: (error, stackTrace) =>
                      const Text('Error loading videos'),
                  data: (videoFiles) {
                    return Column(
                      children: [
                        Text(
                          videoFiles.length.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Edited Videos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        )
                      ],
                    );
                  },
                )
          ],
        );
      },
    );
  }

  Widget _buildImageGridSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ref.watch(userMediaFilesProvider).when(
              loading: () => const Center(
                child: Loader(),
              ),
              error: (err, stackTrace) => Center(
                child: ErrorScreen(
                  error: 'Failed to load images: ${err.toString()}',
                ),
              ),
              data: (mediaFiles) {
                if (mediaFiles.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No edited images yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: mediaFiles.length,
                  itemBuilder: (context, index) {
                    final mediaFile = mediaFiles[index];
                    final blobId = mediaFile['blobId'] as String;

                    return _buildImageGridItem(
                      context: context,
                      ref: ref,
                      blobId: blobId,
                      mediaFile: mediaFile,
                    );
                  },
                );
              },
            ),
      ],
    );
  }

  Widget _buildImageGridItem({
    required BuildContext context,
    required WidgetRef ref,
    required String blobId,
    required Map<String, dynamic> mediaFile,
  }) {
    final imagePreviewHandler = ProfileImagePreviewHandler();

    return GestureDetector(
      onTap: () => imagePreviewHandler.showImagePreview(
        context,
        ref,
        blobId,
        mediaFile,
      ),
      onLongPress: () => imagePreviewHandler.showImageOptions(
        context,
        ref,
        blobId,
        mediaFile,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Consumer(
            builder: (context, ref, child) {
              print('🖼️ Building grid item for blobId: $blobId');
              print('📄 Media file data: $mediaFile');

              return ref.watch(blobImageProvider(blobId)).when(
                loading: () {
                  print('⏳ Loading image for blobId: $blobId');
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 4),
                          Text(
                            'Loading...',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                error: (err, stackTrace) {
                  print('💥 Error loading image for blobId: $blobId');
                  print('   Error: $err');
                  print('   Stack: $stackTrace');
                  return Container(
                    color: Colors.red.shade100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            err.toString().length > 20
                                ? '${err.toString().substring(0, 20)}...'
                                : err.toString(),
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                data: (imageFile) {
                  if (imageFile == null) {
                    print('❌ Image file is null for blobId: $blobId');
                    print('   This usually means blob retrieval failed');

                    // Show debug info in the UI
                    return Container(
                      color: Colors.orange.shade100,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_not_supported,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Not found',
                              style: TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${blobId.length > 8 ? blobId.substring(0, 8) : blobId}...',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  print('✅ Successfully got image file: ${imageFile.path}');
                  return Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      print(
                        '💥 Image.file error for ${imageFile.path}: $error',
                      );
                      return Container(
                        color: Colors.yellow.shade100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Broken',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                error.toString().length > 15
                                    ? '${error.toString().substring(0, 15)}...'
                                    : error.toString(),
                                style: const TextStyle(fontSize: 8),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGridSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(
          builder: (context, ref, child) {
            return ref.watch(userVideoFilesProvider).when(
                  loading: () => const Center(
                    child: Loader(),
                  ),
                  error: (err, stackTrace) => Center(
                    child: ErrorScreen(
                      error: 'Failed to load videos: ${err.toString()}',
                    ),
                  ),
                  data: (videoFiles) {
                    if (videoFiles.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No edited videos yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: videoFiles.length,
                      itemBuilder: (context, index) {
                        final videoFile = videoFiles[index];
                        final blobId = videoFile['blobId'] as String;

                        return _buildVideoGridItem(
                          context: context,
                          ref: ref,
                          blobId: blobId,
                          videoFile: videoFile,
                        );
                      },
                    );
                  },
                );
          },
        ),
      ],
    );
  }

  Widget _buildVideoGridItem({
    required BuildContext context,
    required WidgetRef ref,
    required String blobId,
    required Map<String, dynamic> videoFile,
  }) {
    final videoPreviewHandler = ProfileVideoPreviewHandler();

    return GestureDetector(
      onTap: () {
        videoPreviewHandler.showVideoPreview(
          context,
          ref,
          blobId,
          videoFile,
        );
      },
      onLongPress: () {
        videoPreviewHandler.showVideoOptions(
          context,
          ref,
          blobId,
          videoFile,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Consumer(
            builder: (context, ref, child) {
              print('🎥 Building video grid item for blobId: $blobId');
              print('📄 Video file data: $videoFile');

              return ref.watch(blobVideoProvider(blobId)).when(
                loading: () {
                  print('⏳ Loading video for blobId: $blobId');
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 4),
                          Text(
                            'Loading...',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                error: (err, stackTrace) {
                  print('💥 Error loading video for blobId: $blobId');
                  print('   Error: $err');
                  print('   Stack: $stackTrace');
                  return Container(
                    color: Colors.red.shade100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            err.toString().length > 20
                                ? '${err.toString().substring(0, 20)}...'
                                : err.toString(),
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                data: (videoFile) {
                  if (videoFile == null) {
                    print('❌ Video file is null for blobId: $blobId');
                    print('   This usually means blob retrieval failed');

                    return Container(
                      color: Colors.orange.shade100,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.video_library_outlined,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Not found',
                              style: TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${blobId.length > 8 ? blobId.substring(0, 8) : blobId}...',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  print('✅ Successfully got video file: ${videoFile.path}');

                  // For video thumbnails, you could use video_thumbnail package
                  // For now, showing a video placeholder with play icon
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(
                            Icons.video_library,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '00:00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ref.watch(userDataAuthProvider).when(
            loading: () => Loader(),
            error: (err, stackTrace) {
              return ErrorScreen(error: err.toString());
            },
            data: (user) {
              return SingleChildScrollView(
                child: Center(
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
                              user?.email ?? 'No email available',
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
                        _buildStatsSection(ref),
                        Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                          height: 40,
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.grid_on,
                                      color: _page == 0
                                          ? primaryColor
                                          : secondaryColor,
                                    ),
                                    onPressed: () {
                                      print('first button pressed');
                                      ref
                                          .read(selectedTabProvider.notifier)
                                          .state = 'posts';
                                      setState(() {
                                        _page = 0;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.tiktok,
                                      color: _page == 1
                                          ? primaryColor
                                          : secondaryColor,
                                    ),
                                    onPressed: () {
                                      print('second button pressed');
                                      ref
                                          .read(selectedTabProvider.notifier)
                                          .state = 'videos';
                                      setState(() {
                                        _page = 1;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                          height: 40,
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final selectedTab = ref.watch(selectedTabProvider);

                            if (selectedTab == 'posts') {
                              return _buildImageGridSection(ref);
                            } else if (selectedTab == 'videos') {
                              return _buildVideoGridSection(ref);
                            }

                            return Container();
                          },
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
