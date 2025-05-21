import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/repositories/common_blob_storage_repository.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';

// Create a provider for retrieving blobs that includes the current user's ID
final blobProvider =
    FutureProvider.family<Uint8List?, String>((ref, fileId) async {
  final userDataAsync = ref.read(userDataAuthProvider);

  return userDataAsync.when(
    data: (userData) {
      if (userData == null) {
        return null;
      }
      return ref
          .read(commonBlobStorageRepositoryProvider)
          .getBlob(fileId, userData.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class BlobImage extends ConsumerWidget {
  final String fileId;

  const BlobImage({
    required this.fileId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blobAsync = ref.watch(blobProvider(fileId));

    return blobAsync.when(
      data: (data) {
        if (data == null) {
          return const Center(
            child: Icon(Icons.broken_image, size: 70, color: Colors.grey),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            data,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 70, color: Colors.red);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            Text(
              'Error loading image',
              style: TextStyle(color: Colors.red[300], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class BlobVideo extends ConsumerWidget {
  final String fileId;

  const BlobVideo({
    required this.fileId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blobAsync = ref.watch(blobProvider(fileId));

    return blobAsync.when(
      data: (data) {
        if (data == null) {
          return const Center(
            child: Icon(Icons.movie_creation_outlined,
                size: 70, color: Colors.grey),
          );
        }

        // In a real implementation, you would use a video player that supports playing from memory
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: Colors.black12,
              width: 250,
              height: 150,
              child: const Center(
                child: Text(
                  "Video",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const Icon(
              Icons.play_circle_fill,
              size: 50,
              color: Colors.white70,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            Text(
              'Error loading video',
              style: TextStyle(color: Colors.red[300], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class BlobAudio extends ConsumerStatefulWidget {
  final String fileId;

  const BlobAudio({
    required this.fileId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<BlobAudio> createState() => _BlobAudioState();
}

class _BlobAudioState extends ConsumerState<BlobAudio> {
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final blobAsync = ref.watch(blobProvider(widget.fileId));

    return blobAsync.when(
      data: (data) {
        if (data == null) {
          return const Center(
            child:
                Icon(Icons.audio_file_outlined, size: 50, color: Colors.grey),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                  // In a real implementation, you would play the audio from memory here
                },
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_arrow,
                  color: Colors.teal,
                ),
                iconSize: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    widthFactor:
                        0.3, // This would be controlled by audio position
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "0:30", // This would be the duration
                style: TextStyle(color: Colors.teal),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 40, color: Colors.red),
            Text(
              'Error loading audio',
              style: TextStyle(color: Colors.red[300], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
