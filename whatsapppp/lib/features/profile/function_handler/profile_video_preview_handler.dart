import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/multimedia_editing/repository/media_repository.dart';
import 'package:whatsapppp/features/profile/screen/profile_screen.dart';

class ProfileVideoPreviewHandler {
  void showVideoPreview(
    BuildContext context,
    WidgetRef ref,
    String blobId,
    Map<String, dynamic> mediaFile,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              title: Text(
                mediaFile['fileName'] ?? 'Video',
                style: const TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareVideo(context, ref, blobId),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadVideo(context, ref, blobId),
                ),
              ],
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(blobVideoProvider(blobId)).when(
                          loading: () => const Center(
                            child: Loader(),
                          ),
                          error: (err, stackTrace) => const Center(
                            child: Text(
                              'Failed to load video',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          data: (videoFile) {
                            if (videoFile == null) {
                              return const Center(
                                child: Text(
                                  'Video not found',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            return InteractiveViewer(
                              child: VideoPlayer(
                                VideoPlayerController.file(videoFile)
                                  ..initialize().then((_) {
                                    // Ensure the first frame is shown after the video is initialized
                                    // ref
                                    //         .read(
                                    //             videoControllerProvider(blobId)
                                    //                 .notifier)
                                    //         .state =
                                    //     VideoPlayerController.file(videoFile);
                                    // ref
                                    //     .read(videoControllerProvider(blobId)
                                    //         .notifier)
                                    //     .state
                                    //     .play();
                                  }),
                              ),
                            );
                          },
                        );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showVideoOptions(
    BuildContext context,
    WidgetRef ref,
    String blobId,
    Map<String, dynamic> mediaFile,
    String? mediaOwnerId,
  ) {
    // Check if current user is the owner of the media
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = mediaOwnerId == null || currentUserId == mediaOwnerId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text(
                'Share',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _shareVideo(context, ref, blobId),
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text(
                'Download',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _downloadVideo(context, ref, blobId),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Info'),
              onTap: () => showVideoInfo(context, mediaFile),
            ),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _deleteVideo(context, ref, blobId, mediaFile),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _shareVideo(BuildContext context, WidgetRef ref, String blobId) {
    // Implement sharing functionality
    showSnackBar(
      context,
      'Share functionality to be implemented',
    );
  }

  void _downloadVideo(BuildContext context, WidgetRef ref, String blobId) {
    // Implement download functionality
    showSnackBar(
      context,
      'Download functionality to be implemented',
    );
  }

  void showVideoInfo(
    BuildContext context,
    Map<String, dynamic> mediaFile,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Video Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File Name: ${mediaFile['fileName'] ?? 'N/A'}'),
                Text('File Size: ${mediaFile['fileSize'] ?? 'N/A'} bytes'),
                Text('Duration: ${mediaFile['duration'] ?? 'N/A'} seconds'),
                Text('Resolution: ${mediaFile['resolution'] ?? 'N/A'}'),
                if (mediaFile['mediaType'] != null) ...[
                  Text('Media Type: ${mediaFile['mediaType']}'),
                ],
                if (mediaFile['createdAt'] != null) ...[
                  Text(
                    'Created At: ${mediaFile['createdAt'].toDate() ?? 'N/A'}',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _deleteVideo(
    BuildContext context,
    WidgetRef ref,
    String blobId,
    Map<String, dynamic> videoFile,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final mediaRepository = ref.read(mediaRepositoryProvider);
              final userId = mediaRepository.auth.currentUser?.uid;

              if (userId != null) {
                final success =
                    await mediaRepository.deleteVideoFile(blobId, userId);

                if (context.mounted) {
                  showSnackBar(
                    context,
                    success
                        ? 'Video deleted successfully'
                        : 'Failed to delete video',
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
