import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whatsapppp/common/repositories/common_blob_storage_repository.dart';
import 'package:whatsapppp/features/auth/controller/auth_controller.dart';

// Enhanced provider with better error handling and proper querying
final mediaBlobProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, fileId) async {
  try {
    print('MediaBlobProvider: Loading fileId: $fileId');

    final userDataAsync = ref.read(userDataAuthProvider);

    return userDataAsync.when(
      data: (userData) async {
        if (userData == null) {
          print('MediaBlobProvider: No user data available');
          return null;
        }

        print('MediaBlobProvider: User ID: ${userData.uid}');

        try {
          // First get the document metadata from user's own collection
          final userDocSnapshot = await ref
              .read(commonBlobStorageRepositoryProvider)
              .firestore
              .collection('users')
              .doc(userData.uid)
              .collection('media')
              .doc(fileId)
              .get();

          if (userDocSnapshot.exists) {
            final data = userDocSnapshot.data();
            print('MediaBlobProvider: Found in user collection: ${data?.keys}');
            return data;
          }

          print(
              'MediaBlobProvider: Not found in user collection, checking chat partners');

          // Get all chat partners from user's chats collection
          final chatsSnapshot = await ref
              .read(commonBlobStorageRepositoryProvider)
              .firestore
              .collection('users')
              .doc(userData.uid)
              .collection('chats')
              .get();

          // Search through each chat partner's media collection
          for (final chatDoc in chatsSnapshot.docs) {
            final chatPartnerId = chatDoc.id;
            print('MediaBlobProvider: Checking chat partner: $chatPartnerId');

            try {
              final partnerMediaDoc = await ref
                  .read(commonBlobStorageRepositoryProvider)
                  .firestore
                  .collection('users')
                  .doc(chatPartnerId)
                  .collection('media')
                  .doc(fileId)
                  .get();

              if (partnerMediaDoc.exists) {
                final data = partnerMediaDoc.data();
                print(
                    'MediaBlobProvider: Found in partner collection: ${data?.keys}');
                return data;
              }
            } catch (e) {
              print(
                  'MediaBlobProvider: Error checking partner $chatPartnerId: $e');
              // Continue to next partner
            }
          }

          // Also check groups the user is member of
          final groupsSnapshot = await ref
              .read(commonBlobStorageRepositoryProvider)
              .firestore
              .collection('groups')
              .where('membersUid', arrayContains: userData.uid)
              .get();

          for (final groupDoc in groupsSnapshot.docs) {
            final groupId = groupDoc.id;
            print('MediaBlobProvider: Checking group: $groupId');

            try {
              final groupMediaDoc = await ref
                  .read(commonBlobStorageRepositoryProvider)
                  .firestore
                  .collection('groups')
                  .doc(groupId)
                  .collection('media')
                  .doc(fileId)
                  .get();

              if (groupMediaDoc.exists) {
                final data = groupMediaDoc.data();
                print(
                    'MediaBlobProvider: Found in group collection: ${data?.keys}');
                return data;
              }
            } catch (e) {
              print('MediaBlobProvider: Error checking group $groupId: $e');
              // Continue to next group
            }
          }

          print(
              'MediaBlobProvider: File not found in any accessible collection');
          return null;
        } catch (firestoreError) {
          print('MediaBlobProvider: Firestore error: $firestoreError');
          return null;
        }
      },
      loading: () {
        print('MediaBlobProvider: User data loading');
        return null;
      },
      error: (error, stackTrace) {
        print('MediaBlobProvider: User data error: $error');
        return null;
      },
    );
  } catch (e) {
    print('MediaBlobProvider: General error: $e');
    return null;
  }
});

// Provider specifically for status blob data
final statusBlobProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, blobId) async {
  try {
    print('StatusBlobProvider: Loading blobId: $blobId');

    final userDataAsync = ref.read(userDataAuthProvider);

    return userDataAsync.when(
      data: (userData) async {
        if (userData == null) {
          print('StatusBlobProvider: No user data available');
          return null;
        }

        print('StatusBlobProvider: User ID: ${userData.uid}');

        try {
          // Get blob data from status media collection
          final blobDoc = await FirebaseFirestore.instance
              .collection('status')
              .doc('media')
              .collection('blobs')
              .doc(blobId)
              .get();

          if (blobDoc.exists) {
            final data = blobDoc.data();
            print('StatusBlobProvider: Found blob data: ${data?.keys}');
            return data;
          }

          print('StatusBlobProvider: Blob not found');
          return null;
        } catch (firestoreError) {
          print('StatusBlobProvider: Firestore error: $firestoreError');
          return null;
        }
      },
      loading: () {
        print('StatusBlobProvider: User data loading');
        return null;
      },
      error: (error, stackTrace) {
        print('StatusBlobProvider: User data error: $error');
        return null;
      },
    );
  } catch (e) {
    print('StatusBlobProvider: General error: $e');
    return null;
  }
});

// Helper to get or create local file path for media
Future<String?> _getValidLocalPath(
    String fileId, Map<String, dynamic> data) async {
  try {
    print('_getValidLocalPath: Starting for fileId: $fileId');
    print('_getValidLocalPath: Data keys: ${data.keys}');

    // Check if we have a stored local path and if file exists
    if (data.containsKey('localPath')) {
      final storedPath = data['localPath'] as String;
      final file = File(storedPath);
      print('_getValidLocalPath: Checking stored path: $storedPath');

      if (await file.exists()) {
        final fileSize = await file.length();
        print(
            '_getValidLocalPath: Existing file found at: $storedPath (${fileSize} bytes)');
        return storedPath;
      } else {
        print(
            '_getValidLocalPath: Stored path invalid, file not found: $storedPath');
      }
    }

    // Check if we have base64 data to recreate the file
    if (data.containsKey('data')) {
      print('_getValidLocalPath: Recreating file from base64 data');
      final base64Data = data['data'] as String;

      if (base64Data.isEmpty) {
        print('_getValidLocalPath: Base64 data is empty');
        return null;
      }

      print('_getValidLocalPath: Base64 data length: ${base64Data.length}');

      Uint8List bytes;
      try {
        bytes = base64Decode(base64Data);
        print('_getValidLocalPath: Successfully decoded ${bytes.length} bytes');
      } catch (e) {
        print('_getValidLocalPath: Error decoding base64: $e');
        return null;
      }

      // Determine file type and extension
      String extension = '.mp4'; // default
      String mediaType = 'files';

      if (data.containsKey('type')) {
        final mimeType = data['type'] as String;
        print('_getValidLocalPath: MIME type: $mimeType');

        if (mimeType.startsWith('image/')) {
          extension = mimeType == 'image/png' ? '.png' : '.jpg';
          mediaType = 'images';
        } else if (mimeType.startsWith('audio/')) {
          extension = '.mp3';
          mediaType = 'audio';
        } else if (mimeType.startsWith('video/')) {
          extension = '.mp4';
          mediaType = 'videos';
        }
      } else if (data.containsKey('contentType')) {
        final mimeType = data['contentType'] as String;
        print('_getValidLocalPath: Content type: $mimeType');

        if (mimeType.startsWith('image/')) {
          extension = mimeType == 'image/png' ? '.png' : '.jpg';
          mediaType = 'images';
        } else if (mimeType.startsWith('audio/')) {
          extension = '.mp3';
          mediaType = 'audio';
        } else if (mimeType.startsWith('video/')) {
          extension = '.mp4';
          mediaType = 'videos';
        }
      }

      print(
          '_getValidLocalPath: Using extension: $extension, mediaType: $mediaType');

      // Create directory structure
      final appDir = await getApplicationDocumentsDirectory();
      print('_getValidLocalPath: App directory: ${appDir.path}');

      final mediaDir = Directory('${appDir.path}/$mediaType');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
        print('_getValidLocalPath: Created directory: ${mediaDir.path}');
      }

      // Save file with a unique name to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${fileId}_$timestamp$extension';
      final newPath = '${mediaDir.path}/$fileName';

      print('_getValidLocalPath: Creating file at: $newPath');

      try {
        final newFile = File(newPath);
        await newFile.writeAsBytes(bytes, flush: true);

        // Verify file was written correctly
        if (await newFile.exists()) {
          final writtenSize = await newFile.length();
          print(
              '_getValidLocalPath: File created successfully, size: $writtenSize bytes');

          if (writtenSize == bytes.length) {
            return newPath;
          } else {
            print(
                '_getValidLocalPath: File size mismatch: expected ${bytes.length}, got $writtenSize');
            // Try to delete the corrupted file
            try {
              await newFile.delete();
            } catch (e) {
              print('_getValidLocalPath: Failed to delete corrupted file: $e');
            }
            return null;
          }
        } else {
          print('_getValidLocalPath: File was not created');
          return null;
        }
      } catch (e) {
        print('_getValidLocalPath: Error writing file: $e');
        return null;
      }
    }

    // If we have a 'path' field, try to use it directly (assuming it's a valid file path)
    if (data.containsKey('path')) {
      final filePath = data['path'] as String;
      print('_getValidLocalPath: Checking direct path: $filePath');

      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print(
            '_getValidLocalPath: Direct path valid: $filePath (${fileSize} bytes)');
        return filePath;
      } else {
        print(
            '_getValidLocalPath: Direct path invalid, file not found: $filePath');
      }
    }

    print('_getValidLocalPath: No valid data source found');
    print('_getValidLocalPath: Available data keys: ${data.keys.toList()}');

    // Log what data we actually have for debugging
    data.forEach((key, value) {
      if (value is String && value.length > 100) {
        print('_getValidLocalPath: $key: [${value.length} characters]');
      } else {
        print('_getValidLocalPath: $key: $value');
      }
    });

    return null;
  } catch (e, stackTrace) {
    print('_getValidLocalPath: General error: $e');
    print('_getValidLocalPath: Stack trace: $stackTrace');
    return null;
  }
}

// Fixed Image widget with better debugging and error handling
class BlobImage extends ConsumerWidget {
  final String fileId;
  final double? width;
  final double? height;
  final BoxFit fit;

  const BlobImage({
    required this.fileId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('BlobImage: Building for fileId: $fileId');
    final blobDataAsync = ref.watch(mediaBlobProvider(fileId));

    return blobDataAsync.when(
      data: (data) {
        print('BlobImage: Data received: ${data != null ? data.keys : 'null'}');

        if (data == null) {
          return _buildErrorWidget('Image not found in database');
        }

        return _buildImageWidget(data);
      },
      loading: () {
        print('BlobImage: Loading state');
        return Container(
          width: width ?? 200,
          height: height ?? 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      error: (err, stack) {
        print('BlobImage: Error state: $err');
        return Container(
          width: width ?? 200,
          height: height ?? 200,
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 30, color: Colors.red),
                const SizedBox(height: 4),
                Text(
                  'Error: $err',
                  style: TextStyle(color: Colors.red[700], fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(Map<String, dynamic> data) {
    try {
      print('BlobImage: Processing data: ${data.keys}');
      Uint8List? imageData;

      // Check different data formats
      if (data.containsKey('data')) {
        // Direct base64 data
        final base64String = data['data'] as String;
        print('BlobImage: Found base64 data, length: ${base64String.length}');

        final estimatedSize = (base64String.length * 3) ~/ 4;
        print('BlobImage: Estimated size: $estimatedSize bytes');

        if (estimatedSize > 10 * 1024 * 1024) {
          // 10MB limit
          return _buildErrorWidget(
              'Image too large (${(estimatedSize / (1024 * 1024)).toStringAsFixed(1)}MB)');
        }

        try {
          imageData = base64Decode(base64String);
          print(
              'BlobImage: Successfully decoded base64, ${imageData.length} bytes');
        } catch (e) {
          print('BlobImage: Error decoding base64: $e');
          return _buildErrorWidget('Invalid base64 data');
        }
      } else if (data.containsKey('localPath')) {
        // Local file path
        final localPath = data['localPath'] as String;
        print('BlobImage: Found local path: $localPath');

        final file = File(localPath);
        if (file.existsSync()) {
          try {
            imageData = file.readAsBytesSync();
            print(
                'BlobImage: Successfully read local file, ${imageData.length} bytes');
          } catch (e) {
            print('BlobImage: Error reading local file: $e');
            return _buildErrorWidget('Cannot read local file');
          }
        } else {
          print('BlobImage: Local file does not exist');
          return _buildErrorWidget('Local file not found');
        }
      } else {
        print('BlobImage: No recognized data format found');
        print('BlobImage: Available keys: ${data.keys}');
        return _buildErrorWidget('No image data found');
      }

      if (imageData.isEmpty) {
        print('BlobImage: Image data is null or empty');
        return _buildErrorWidget('Empty image data');
      }

      print('BlobImage: Creating Image.memory widget');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width,
          height: height,
          child: Image.memory(
            imageData,
            fit: fit,
            gaplessPlayback: true,
            cacheWidth: width?.toInt(),
            cacheHeight: height?.toInt(),
            errorBuilder: (context, error, stackTrace) {
              print('BlobImage: Image.memory error: $error');
              print('BlobImage: Stack trace: $stackTrace');
              return _buildErrorWidget('Invalid image format');
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('BlobImage: Exception in _buildImageWidget: $e');
      print('BlobImage: Stack trace: $stackTrace');
      return _buildErrorWidget('Error processing image: $e');
    }
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      width: width ?? 200,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                message,
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fixed Video widget with better debugging and path handling
class BlobVideo extends ConsumerStatefulWidget {
  final String fileId;
  final double? width;
  final double? height;

  const BlobVideo({
    required this.fileId,
    this.width,
    this.height,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<BlobVideo> createState() => _BlobVideoState();
}

class _BlobVideoState extends ConsumerState<BlobVideo> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _showThumbnailOnly = true;
  bool _hasError = false;
  Uint8List? _thumbnailData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('BlobVideo: Initializing for fileId: ${widget.fileId}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadVideoData();
  }

  Future<void> _loadVideoData() async {
    print('BlobVideo: Loading video data for ${widget.fileId}');

    try {
      // Wait for the future to complete
      final data = await ref.read(mediaBlobProvider(widget.fileId).future);

      if (!mounted) return;

      if (data == null) {
        print('BlobVideo: No data found');
        setState(() {
          _hasError = true;
          _errorMessage = 'Video not found in database';
        });
        return;
      }

      print('BlobVideo: Data keys: ${data.keys}');

      // Handle thumbnail data first
      if (data.containsKey('thumbnail')) {
        try {
          final thumbnailBase64 = data['thumbnail'] as String;
          print(
              'BlobVideo: Found thumbnail, length: ${thumbnailBase64.length}');
          setState(() {
            _thumbnailData = base64Decode(thumbnailBase64);
          });
        } catch (e) {
          print('BlobVideo: Error decoding video thumbnail: $e');
        }
      }

      // Get valid video file path
      final videoPath = await _getValidLocalPath(widget.fileId, data);

      if (videoPath == null) {
        print('BlobVideo: No valid video path available');
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not accessible';
        });
        return;
      }

      print('BlobVideo: Using video path: $videoPath');

      try {
        _controller = VideoPlayerController.file(File(videoPath));

        _controller!.addListener(() {
          if (_controller!.value.hasError) {
            print(
                'BlobVideo: Video player error: ${_controller!.value.errorDescription}');
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage =
                    'Video playback error: ${_controller!.value.errorDescription}';
              });
            }
          }
        });

        await _controller!.initialize();
        print('BlobVideo: Controller initialized successfully');

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        print('BlobVideo: Error initializing video controller: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Cannot initialize video: $e';
          });
        }
      }
    } catch (e) {
      print('BlobVideo: Error loading video data: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error loading video: $e';
        });
      }
    }
  }

  void _playVideo() {
    print('BlobVideo: Play button pressed');
    if (_controller != null && _isInitialized && !_hasError) {
      setState(() {
        _showThumbnailOnly = false;
        _isPlaying = true;
      });
      _controller!.play();
    } else {
      print(
          'BlobVideo: Cannot play - controller: ${_controller != null}, initialized: $_isInitialized, hasError: $_hasError');
    }
  }

  void _pauseVideo() {
    print('BlobVideo: Pause button pressed');
    if (_controller != null && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    print('BlobVideo: Disposing controller');
    _controller?.removeListener(() {});
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      print('BlobVideo: Showing error state: $_errorMessage');
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 50, color: Colors.grey),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage ?? 'Video unavailable',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showThumbnailOnly && _thumbnailData != null) {
      print('BlobVideo: Showing thumbnail');
      return GestureDetector(
        onTap: _playVideo,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _thumbnailData!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    print('BlobVideo: Thumbnail error: $error');
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.videocam_off, size: 50),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.6),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isInitialized && _controller != null) {
      print('BlobVideo: Showing video player');
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            if (_isPlaying)
              GestureDetector(
                onTap: _pauseVideo,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.play_circle_fill,
                  size: 60,
                  color: Colors.white70,
                ),
                onPressed: _playVideo,
              ),
          ],
        ),
      );
    }

    // Loading state
    print('BlobVideo: Showing loading state');
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Fixed Audio widget with better debugging and path handling
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _audioPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('BlobAudio: Initializing for fileId: ${widget.fileId}');
    _setupAudioPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAudioData();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  Future<void> _loadAudioData() async {
    print('BlobAudio: Loading audio data');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final data = await ref.read(mediaBlobProvider(widget.fileId).future);

      if (!mounted) return;

      if (data == null) {
        print('BlobAudio: No data found');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Audio not found in database';
        });
        return;
      }

      print('BlobAudio: Data keys: ${data.keys}');

      // Get valid audio file path
      final audioPath = await _getValidLocalPath(widget.fileId, data);

      if (audioPath == null) {
        print('BlobAudio: No valid audio path available');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Audio file not accessible';
        });
        return;
      }

      _audioPath = audioPath;
      print('BlobAudio: Using audio path: $_audioPath');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('BlobAudio: Error loading audio data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load audio: $e';
        });
      }
    }
  }

  void _playPause() async {
    print('BlobAudio: Play/Pause button pressed');
    if (_hasError || _audioPath == null) {
      print(
          'BlobAudio: Cannot play - hasError: $_hasError, audioPath: $_audioPath');
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
      }
    } catch (e) {
      print('BlobAudio: Error playing audio: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Playback error: $e';
      });
    }
  }

  void _seekTo(double value) async {
    if (_hasError) return;

    try {
      final newPosition = Duration(seconds: value.toInt());
      await _audioPlayer.seek(newPosition);
    } catch (e) {
      print('BlobAudio: Error seeking audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    print('BlobAudio: Disposing audio player');
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Loading audio...'),
          ],
        ),
      );
    }

    if (_hasError || _audioPath == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _errorMessage ?? 'Audio unavailable',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _playPause,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.teal,
              size: 40,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _duration.inSeconds > 0
                        ? _position.inSeconds
                            .toDouble()
                            .clamp(0.0, _duration.inSeconds.toDouble())
                        : 0.0,
                    min: 0,
                    max: _duration.inSeconds.toDouble() > 0
                        ? _duration.inSeconds.toDouble()
                        : 1,
                    activeColor: Colors.teal,
                    onChanged: _seekTo,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
