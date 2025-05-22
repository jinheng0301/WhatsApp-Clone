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

// Enhanced provider with better error handling and caching
final mediaBlobProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, fileId) async {
  try {
    final userDataAsync = ref.read(userDataAuthProvider);

    return userDataAsync.when(
      data: (userData) async {
        if (userData == null) {
          return null;
        }

        // First get the document metadata
        final docSnapshot = await ref
            .read(commonBlobStorageRepositoryProvider)
            .firestore
            .collection('users')
            .doc(userData.uid)
            .collection('media')
            .doc(fileId)
            .get();

        if (!docSnapshot.exists) {
          // Try to find in other users' collections
          final querySnapshot = await ref
              .read(commonBlobStorageRepositoryProvider)
              .firestore
              .collectionGroup('media')
              .where(FieldPath.documentId, isEqualTo: fileId)
              .limit(1)
              .get();

          if (querySnapshot.docs.isEmpty) {
            return null;
          }

          return querySnapshot.docs.first.data();
        }

        return docSnapshot.data();
      },
      loading: () => null,
      error: (_, __) => null,
    );
  } catch (e) {
    print('MediaBlobProvider error: $e');
    return null;
  }
});

// Fixed Image widget with better memory management
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
    final blobDataAsync = ref.watch(mediaBlobProvider(fileId));

    return blobDataAsync.when(
      data: (data) {
        if (data == null) {
          return Container(
            width: width ?? 200,
            height: height ?? 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          );
        }

        return _buildImageWidget(data);
      },
      loading: () => Container(
        width: width ?? 200,
        height: height ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Container(
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
                'Error loading image',
                style: TextStyle(color: Colors.red[700], fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(Map<String, dynamic> data) {
    try {
      Uint8List? imageData;

      if (data.containsKey('data')) {
        // Direct base64 data - check size first
        final base64String = data['data'] as String;
        final estimatedSize =
            (base64String.length * 3) ~/ 4; // Rough base64 to bytes conversion

        if (estimatedSize > 5 * 1024 * 1024) {
          // 5MB limit
          return _buildErrorWidget('Image too large');
        }

        try {
          imageData = base64Decode(base64String);
        } catch (e) {
          print('Error decoding base64 image: $e');
          return _buildErrorWidget('Invalid image data');
        }
      } else if (data.containsKey('localPath')) {
        final file = File(data['localPath']);
        if (file.existsSync()) {
          try {
            imageData = file.readAsBytesSync();
          } catch (e) {
            print('Error reading local image file: $e');
            return _buildErrorWidget('Cannot read file');
          }
        }
      }

      if (imageData == null || imageData.isEmpty) {
        return _buildErrorWidget('No image data');
      }

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
              print('Image.memory error: $error');
              return _buildErrorWidget('Invalid image');
            },
          ),
        ),
      );
    } catch (e) {
      print('Error building image widget: $e');
      return _buildErrorWidget('Error loading image');
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
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Fixed Video widget with better resource management
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
    _loadVideoData();
  }

  Future<void> _loadVideoData() async {
    try {
      final videoDataAsync = ref.read(mediaBlobProvider(widget.fileId));

      videoDataAsync.whenData((data) async {
        if (data == null) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Video not found';
          });
          return;
        }

        // Handle thumbnail data first
        if (data.containsKey('thumbnail')) {
          try {
            setState(() {
              _thumbnailData = base64Decode(data['thumbnail']);
            });
          } catch (e) {
            print('Error decoding video thumbnail: $e');
          }
        }

        // Check if this is a local storage video
        if (data.containsKey('localPath')) {
          final localPath = data['localPath'] as String;
          final file = File(localPath);

          if (await file.exists()) {
            try {
              // Initialize with file
              _controller = VideoPlayerController.file(file);

              // Add error listener
              _controller!.addListener(() {
                if (_controller!.value.hasError) {
                  print(
                      'Video player error: ${_controller!.value.errorDescription}');
                  if (mounted) {
                    setState(() {
                      _hasError = true;
                      _errorMessage = 'Video playback error';
                    });
                  }
                }
              });

              await _controller!.initialize();

              if (mounted) {
                setState(() {
                  _isInitialized = true;
                });
              }
            } catch (e) {
              print('Error initializing video controller: $e');
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Cannot load video';
                });
              }
            }
          } else {
            setState(() {
              _hasError = true;
              _errorMessage = 'Video file not found';
            });
          }
        }
      });
    } catch (e) {
      print('Error loading video data: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading video';
      });
    }
  }

  void _playVideo() {
    if (_controller != null && _isInitialized && !_hasError) {
      setState(() {
        _showThumbnailOnly = false;
        _isPlaying = true;
      });
      _controller!.play();
    }
  }

  void _pauseVideo() {
    if (_controller != null && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(() {});
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
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
              Text(
                _errorMessage ?? 'Video unavailable',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_showThumbnailOnly && _thumbnailData != null) {
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

// Fixed Audio widget with better resource management
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
    _setupAudioPlayer();
    _loadAudioData();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  Future<void> _loadAudioData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final audioDataAsync = ref.read(mediaBlobProvider(widget.fileId));

      audioDataAsync.whenData((data) async {
        if (data == null) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Audio not found';
          });
          return;
        }

        try {
          // Handle audio data based on storage type
          if (data.containsKey('localPath')) {
            // Local file path
            final localPath = data['localPath'] as String;
            final file = File(localPath);

            if (await file.exists()) {
              _audioPath = localPath;
              // Don't set source here, wait for play
            } else {
              setState(() {
                _hasError = true;
                _errorMessage = 'Audio file not found';
              });
            }
          } else if (data.containsKey('data')) {
            // Base64 encoded data
            final base64Data = data['data'] as String;

            try {
              final bytes = base64Decode(base64Data);

              // Write to temporary file
              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/${widget.fileId}.mp3');
              await tempFile.writeAsBytes(bytes);

              _audioPath = tempFile.path;
            } catch (e) {
              print('Error processing audio data: $e');
              setState(() {
                _hasError = true;
                _errorMessage = 'Invalid audio data';
              });
            }
          } else {
            setState(() {
              _hasError = true;
              _errorMessage = 'Unknown audio format';
            });
          }
        } catch (e) {
          print('Error processing audio: $e');
          setState(() {
            _hasError = true;
            _errorMessage = 'Error processing audio';
          });
        }

        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      print('BlobAudio: Error loading audio data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load audio';
      });
    }
  }

  void _playPause() async {
    if (_hasError || _audioPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
      }
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Playback error';
      });
    }
  }

  void _seekTo(double value) async {
    if (_hasError) return;

    try {
      final newPosition = Duration(seconds: value.toInt());
      await _audioPlayer.seek(newPosition);
    } catch (e) {
      print('Error seeking audio: $e');
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
            Text(
              _errorMessage ?? 'Audio unavailable',
              style: const TextStyle(color: Colors.red),
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
          // Play/Pause button
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

          // Progress bar and timestamps
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
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
