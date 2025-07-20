import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/multimedia_editing/controller/voice_over_preview_controller.dart';
import 'package:whatsapppp/features/multimedia_editing/repository/media_repository.dart';
import 'package:whatsapppp/features/multimedia_editing/services/audio_service.dart';
import 'package:whatsapppp/features/profile/screen/profile_screen.dart';

class ProfileImagePreviewHandler {
  bool _hasVoiceOver(Map<String, dynamic> mediaFile) {
    // Check multiple indicators for voice-over content
    final bool hasVoiceOverFlag = mediaFile['hasVoiceOver'] == true;
    final bool hasVoiceOverPath = mediaFile['voiceOverPath'] != null &&
        (mediaFile['voiceOverPath'] as String).isNotEmpty;
    final bool hasVoiceOverType =
        mediaFile['mediaType'] == 'image_with_voiceover';
    final bool mediaTypeContainsVoiceover =
        mediaFile['mediaType']?.toString().contains('voiceover') == true;

    // NEW: Check original filename for voice-over indicators
    final String? originalFileName = mediaFile['originalFileName'] as String?;
    final bool fileNameIndicatesVoiceOver = originalFileName != null &&
        (originalFileName.contains('voiceover') ||
            originalFileName.contains('with_voiceover') ||
            originalFileName.endsWith(
                '.mp4')); // Video files often indicate voice-over content

    // NEW: Check if there are audio-related fields
    final bool hasAudioPath = mediaFile['audioPath'] != null;
    final bool hasVoiceOverUrl = mediaFile['voiceOverUrl'] != null;

    print('🎤 Voice-over detection for ${mediaFile['blobId']}:');
    print('   - hasVoiceOverFlag: $hasVoiceOverFlag');
    print('   - hasVoiceOverPath: $hasVoiceOverPath');
    print('   - hasVoiceOverType: $hasVoiceOverType');
    print('   - mediaTypeContainsVoiceover: $mediaTypeContainsVoiceover');
    print('   - fileNameIndicatesVoiceOver: $fileNameIndicatesVoiceOver');
    print('   - hasAudioPath: $hasAudioPath');
    print('   - hasVoiceOverUrl: $hasVoiceOverUrl');
    print('   - originalFileName: $originalFileName');

    return hasVoiceOverFlag ||
        hasVoiceOverPath ||
        hasVoiceOverType ||
        mediaTypeContainsVoiceover ||
        fileNameIndicatesVoiceOver ||
        hasAudioPath ||
        hasVoiceOverUrl;
  }

  void showImagePreview(
    BuildContext context,
    WidgetRef ref,
    String blobId,
    Map<String, dynamic> mediaFile,
  ) {
    // Check if this image has a voice-over
    final bool hasVoiceOver = _hasVoiceOver(mediaFile);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      mediaFile['fileName'] ?? 'Image',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (hasVoiceOver) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.mic,
                      color: Colors.purple,
                      size: 16,
                    ),
                  ],
                ],
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareImage(context, ref, blobId),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadImage(context, ref, blobId),
                ),
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Consumer(
                  builder: (context, ref, child) {
                    // Use the voice-over specific provider if needed
                    final provider = hasVoiceOver
                        ? voiceOverImageProvider(blobId)
                        : blobImageProvider(blobId);

                    return ref.watch(provider).when(
                          loading: () => const Center(
                            child: Loader(),
                          ),
                          error: (err, stackTrace) => const Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          data: (imageFile) {
                            if (imageFile == null) {
                              return const Center(
                                child: Text(
                                  'Image not found',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            return Stack(
                              children: [
                                InteractiveViewer(
                                  child: Image.file(
                                    imageFile,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                // Voice-over controls overlay
                                if (hasVoiceOver)
                                  _buildVoiceOverControls(
                                    context,
                                    mediaFile,
                                    blobId,
                                  ),
                              ],
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

  // New method to build voice-over controls
  Widget _buildVoiceOverControls(
      BuildContext context, Map<String, dynamic> mediaFile, String blobId) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.5)),
        ),
        child: VoiceOverPreviewController(
          mediaFile: mediaFile,
          blobId: blobId,
        ),
      ),
    );
  }

  void showImageOptions(
    BuildContext context,
    WidgetRef ref,
    String blobId,
    Map<String, dynamic> mediaFile,
    String? mediaOwnerId,
  ) {
    // Check if current user is the owner of the media
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = mediaOwnerId == null || currentUserId == mediaOwnerId;
    final bool hasVoiceOver = _hasVoiceOver(mediaFile);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice-over indicator header
            if (hasVoiceOver)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, color: Colors.purple, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Voice-Over Content',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            if (hasVoiceOver) const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareImage(context, ref, blobId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                _downloadImage(context, ref, blobId);
              },
            ),
            // Voice-over specific options
            if (hasVoiceOver) ...[
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.purple),
                title: const Text('Play Voice-Over'),
                subtitle: Text(_getVoiceOverInfo(mediaFile)),
                onTap: () {
                  Navigator.pop(context);
                  _playVoiceOver(context, mediaFile, blobId);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.download_outlined, color: Colors.purple),
                title: const Text('Download Voice-Over'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadVoiceOver(context, ref, blobId);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Info'),
              onTap: () {
                Navigator.pop(context);
                _showImageInfo(context, mediaFile);
              },
            ),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteImage(context, ref, blobId, mediaFile);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to get voice-over info
  String _getVoiceOverInfo(Map<String, dynamic> mediaFile) {
    final voiceOverPath = mediaFile['voiceOverPath'] as String?;
    if (voiceOverPath != null) {
      return 'Audio file attached';
    }
    return 'Voice-over available';
  }

  void _shareImage(BuildContext context, WidgetRef ref, String blobId) {
    // Implement sharing functionality
    showSnackBar(
      context,
      'Share functionality to be implemented',
    );
  }

  void _downloadImage(BuildContext context, WidgetRef ref, String blobId) {
    // Implement download functionality
    showSnackBar(
      context,
      'Download functionality to be implemented',
    );
  }

  // New methods for voice-over functionality
  void _playVoiceOver(
      BuildContext context, Map<String, dynamic> mediaFile, String blobId) {
    try {
      // Extract voice-over path from mediaFile or construct it
      final voiceOverPath = mediaFile['voiceOverPath'] as String?;
      if (voiceOverPath != null) {
        AudioService.previewAudio(voiceOverPath);
        showSnackBar(context, 'Playing voice-over...');
      } else {
        showSnackBar(context, 'Voice-over path not found');
      }
    } catch (e) {
      showSnackBar(context, 'Error playing voice-over: $e');
    }
  }

  void _downloadVoiceOver(BuildContext context, WidgetRef ref, String blobId) {
    // Implement voice-over download functionality
    showSnackBar(
      context,
      'Voice-over download functionality to be implemented',
    );
  }

  void _showImageInfo(
    BuildContext context,
    Map<String, dynamic> mediaFile,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Image Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Name: ${mediaFile['fileName'] ?? 'Unknown'}'),
              Text('Original: ${mediaFile['originalFileName'] ?? 'Unknown'}'),
              Text('Type: ${mediaFile['mediaType'] ?? 'Unknown'}'),
              Text('Storage: ${mediaFile['storageType'] ?? 'Unknown'}'),
              if (mediaFile['projectId'] != null)
                Text('Project: ${mediaFile['projectId']}'),
              if (mediaFile['createdAt'] != null)
                Text('Created: ${mediaFile['createdAt'].toDate()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _deleteImage(
    BuildContext context,
    WidgetRef ref,
    String blobId,
    Map<String, dynamic> mediaFile,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final mediaRepository = ref.read(mediaRepositoryProvider);
              final userId = mediaRepository.auth.currentUser?.uid;

              if (userId != null) {
                final success =
                    await mediaRepository.deleteMediaFile(blobId, userId);

                if (context.mounted) {
                  showSnackBar(
                    context,
                    success
                        ? 'Image deleted successfully'
                        : 'Failed to delete image',
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
