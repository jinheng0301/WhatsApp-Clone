import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/widgets/error.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';
import 'package:whatsapppp/features/multimedia_editing/repository/media_repository.dart';
import 'package:whatsapppp/features/profile/function_handler/profile_handler.dart';

// Provider for user's media files
final userMediaFilesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  return mediaRepository.getUserMediaFiles();
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

class ProfileScreen extends ConsumerWidget {
  static const String routeName = '/profile-screen';
  const ProfileScreen({super.key});

  final int numOfShortVideos = 0;

  Widget _buildStatsSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        return ref.watch(userMediaFilesProvider).when(
              loading: () => const Text('Loading stats...'),
              error: (err, stackTrace) => const Text('Error loading stats'),
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
            );
      },
    );
  }

  Widget _buildMediaGridSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(
          builder: (context, ref, child) {
            return ref.watch(userMediaFilesProvider).when(
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: mediaFiles.length,
                      itemBuilder: (context, index) {
                        final mediaFile = mediaFiles[index];
                        final blobId = mediaFile['blobId'] as String;

                        return _buildMediaGridItem(
                          context: context,
                          ref: ref,
                          blobId: blobId,
                          mediaFile: mediaFile,
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

  Widget _buildMediaGridItem({
    required BuildContext context,
    required WidgetRef ref,
    required String blobId,
    required Map<String, dynamic> mediaFile,
  }) {
    final imagePreviewHandler = ImagePreviewHandler();

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        _buildMediaGridSection(ref)
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
