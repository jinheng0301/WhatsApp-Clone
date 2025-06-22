import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/multimedia_editing/services/media_editor_service.dart';

// Model for overlay items
class OverlayItem {
  final String id;
  final String content;
  final OverlayType type;
  Offset position;
  double fontSize;
  Color color;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool isSelected;
  double rotation;
  double scale;
  Duration? startTime;
  Duration? endTime;

  OverlayItem({
    required this.id,
    required this.content,
    required this.type,
    required this.position,
    this.fontSize = 24.0,
    this.color = Colors.white,
    this.fontFamily = 'Roboto',
    this.isBold = false,
    this.isItalic = false,
    this.isSelected = false,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.startTime,
    this.endTime,
  });
}

enum OverlayType { text, sticker }

class PreviewPanel extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final Function(List<OverlayItem>)? onOverlaysChanged;

  const PreviewPanel({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    this.onOverlaysChanged,
  });

  @override
  State<PreviewPanel> createState() => PreviewPanelState();
}

class PreviewPanelState extends State<PreviewPanel> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  List<OverlayItem> _overlayItems = [];
  OverlayItem? _selectedItem;
  Size _previewSize = Size.zero;

  // Video editing specific properties
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  Duration _startTrim = Duration.zero;
  Duration _endTrim = Duration.zero;
  bool _isLooping = false;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;

  // Variables for gesture handling
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  Offset _initialFocalPoint = Offset.zero;

  // Add offset tracking for split videos
  Duration _videoStartOffset = Duration.zero; // Tracks original start time

  // Add this property to track dynamic video state
  bool _isDynamicVideo = false;
  // Tracks if image became video due to voice over

  String _currentMediaPath = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentMediaPath = widget.mediaPath;
    if (widget.isVideo) {
      _initializeVideoPlayer();
    }

    // Check if it's a video file regardless of the initial isVideo flag
    _checkAndInitializeMedia();
  }

  // New method to check media type and initialize appropriately
  void _checkAndInitializeMedia() {
    final isVideoFile = widget.mediaPath.toLowerCase().endsWith('.mp4') ||
        widget.mediaPath.toLowerCase().endsWith('.mov') ||
        widget.mediaPath.toLowerCase().endsWith('.avi') ||
        widget.mediaPath.toLowerCase().endsWith('.mkv');

    if (isVideoFile) {
      _isDynamicVideo = true;
      _initializeVideoPlayer();
    }
  }

  // Add method to handle media path updates (for voice over)
  void updateMediaPath(String newPath) {
    // Dispose existing video controller if any
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _isInitialized = false;
      _isDynamicVideo = false;
      _isPlaying = false;
    });

    // Update the widget's mediaPath reference
    // Note: You might need to pass this through a callback to parent

    // Check if new path is video
    final isVideoFile = newPath.toLowerCase().endsWith('.mp4') ||
        newPath.toLowerCase().endsWith('.mov') ||
        newPath.toLowerCase().endsWith('.avi') ||
        newPath.toLowerCase().endsWith('.mkv');

    if (isVideoFile) {
      _isDynamicVideo = true;
      // Initialize video player for the new video file
      _videoController = VideoPlayerController.file(File(newPath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _videoDuration = _videoController!.value.duration;
              _endTrim = _videoDuration;
              _currentPosition = Duration.zero;
              _startTrim = Duration.zero;
            });

            _videoController!.addListener(_onVideoPositionChanged);
            _videoController!.seekTo(Duration.zero);

            // ADDED: Set volume to ensure audio is audible
            _videoController!.setVolume(1.0);

            print(
                'Voice over video initialized. Duration: ${_formatDuration(_videoDuration)}');
          }
        }).catchError((error) {
          print('Error initializing video after voice over: $error');
        });
    } else {
      // Handle case where it's still an image (shouldn't happen with voice over)
      print('Media path updated but not a video file: $newPath');
    }
  }

  Future<void> applyVideoFilter(String filterType) async {
    if (!isCurrentlyVideo || widget.mediaPath.isEmpty) return;

    try {
      // Show loading indicator
      setState(() {
        _isInitialized = false;
      });

      // Apply filter using MediaEditorService
      final newPath = await MediaEditorService.applyFilter(
        mediaPath: widget.mediaPath,
        filterType: filterType,
        isVideo: true,
      );

      // Dispose current video controller
      _videoController?.dispose();
      _videoController = null;

      // Initialize new video with filtered path
      _videoController = VideoPlayerController.file(File(newPath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _videoDuration = _videoController!.value.duration;
              _endTrim = _videoDuration;
              _currentPosition = Duration.zero;
              _startTrim = Duration.zero;
            });

            _videoController!.addListener(_onVideoPositionChanged);
            _videoController!.seekTo(Duration.zero);
            _videoController!.setVolume(_volume);

            print('Video filter "$filterType" applied successfully');
          }
        }).catchError((error) {
          print('Error initializing filtered video: $error');
          setState(() {
            _isInitialized = true; // Reset to show error state
          });
        });

      // Notify parent about path change if needed
      // You might want to add a callback to notify the parent widget
      // widget.onVideoPathChanged?.call(newPath);
    } catch (e) {
      print('Error applying video filter: $e');
      setState(() {
        _isInitialized = true;
      });
      // You might want to show an error message to user
    }
  }

// Method to apply effect to current video
  Future<void> applyVideoEffect(String effectType) async {
    if (!isCurrentlyVideo || widget.mediaPath.isEmpty) return;

    try {
      // Show loading indicator
      setState(() {
        _isInitialized = false;
      });

      // Apply effect using MediaEditorService
      final newPath = await MediaEditorService.applyEffect(
        mediaPath: widget.mediaPath,
        effectType: effectType,
        isVideo: true,
      );

      // Dispose current video controller
      _videoController?.dispose();
      _videoController = null;

      // Initialize new video with effect applied
      _videoController = VideoPlayerController.file(File(newPath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _videoDuration = _videoController!.value.duration;
              _endTrim = _videoDuration;
              _currentPosition = Duration.zero;
              _startTrim = Duration.zero;
            });

            _videoController!.addListener(_onVideoPositionChanged);
            _videoController!.seekTo(Duration.zero);
            _videoController!.setVolume(_volume);

            print('Video effect "$effectType" applied successfully');
          }
        }).catchError((error) {
          print('Error initializing video with effect: $error');
          setState(() {
            _isInitialized = true; // Reset to show error state
          });
        });

      // Notify parent about path change if needed
      // widget.onVideoPathChanged?.call(newPath);
    } catch (e) {
      print('Error applying video effect: $e');
      setState(() {
        _isInitialized = true;
      });
      // You might want to show an error message to user
    }
  }

  // Make these methods public for external access
  void playVideo() => _playVideo();
  void pauseVideo() => _pauseVideo();

  // Add method to sync timeline position with video position
  void updateTimelinePosition(Duration position) {
    if (widget.isVideo && _videoController != null) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  // Modified initialization for split videos
  void _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(File(widget.mediaPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _videoDuration = _videoController!.value.duration;
            _endTrim = _videoDuration;
            // Reset current position when loading split video
            _currentPosition = Duration.zero;
          });

          // Listen to video position changes
          _videoController!.addListener(_onVideoPositionChanged);

          // Seek to beginning to ensure proper start
          _videoController!.seekTo(Duration.zero);
        }
      }).catchError((error) {
        print('Error initializing video: $error');
      });
  }

  // Method to handle video splitting and reload
  void handleVideoSplit(String newVideoPath, Duration originalSplitPoint) {
    // Store the original offset
    _videoStartOffset = originalSplitPoint;

    // Dispose current controller
    _videoController?.dispose();

    // Update the media path
    setState(() {
      _isInitialized = false;
    });

    // Reinitialize with new video
    _videoController = VideoPlayerController.file(File(newVideoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _videoDuration = _videoController!.value.duration;
            _endTrim = _videoDuration;
            _currentPosition = Duration.zero;
            _startTrim = Duration.zero;
          });

          _videoController!.addListener(_onVideoPositionChanged);
          _videoController!.seekTo(Duration.zero);

          print(
              'Video split and reloaded. New duration: ${_formatDuration(_videoDuration)}');
          print('Original start offset: ${_formatDuration(_videoStartOffset)}');
        }
      });
  }

  // Enhanced video position listener with timeline sync
  void _onVideoPositionChanged() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final position = _videoController!.value.position;

      // Check if video is playing within trim range
      if (_isPlaying && position >= _endTrim) {
        if (_isLooping) {
          _videoController!.seekTo(_startTrim);
        } else {
          _pauseVideo();
        }
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        // You could add a callback here to update timeline
        // widget.onPositionChanged?.call(position);
      }
    }
  }

  // Enhanced video control methods
  void _playVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      // Ensure we're within trim range
      if (_currentPosition < _startTrim || _currentPosition > _endTrim) {
        _videoController!.seekTo(_startTrim);
      }

      _videoController!.play();
      setState(() => _isPlaying = true);
    }
  }

  void _pauseVideo() {
    if (_videoController != null) {
      _videoController!.pause();
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  // Video editing specific methods
  void setTrimRange(Duration start, Duration end) {
    if (start < Duration.zero || end > _videoDuration || start >= end) {
      print('Invalid trim range: $start - $end');
      return;
    }

    setState(() {
      _startTrim = start;
      _endTrim = end;
    });

    // If currently playing and outside trim range, seek to start
    if (_videoController != null && _isPlaying) {
      if (_currentPosition < start || _currentPosition > end) {
        _videoController!.seekTo(start);
      }
    }

    // Notify parent component about trim changes
    print(
        'Trim range set: ${_formatDuration(start)} - ${_formatDuration(end)}');
  }

  void seekToPosition(Duration position) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      // Clamp position within trim range
      final clampedPosition = Duration(
        milliseconds: position.inMilliseconds.clamp(
          _startTrim.inMilliseconds,
          _endTrim.inMilliseconds,
        ),
      );

      _videoController!.seekTo(clampedPosition);
      setState(() => _currentPosition = clampedPosition);
    }
  }

  void setPlaybackSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    if (_videoController != null) {
      _videoController!.setPlaybackSpeed(speed);
    }
  }

  void setVolume(double volume) {
    setState(() => _volume = volume);
    if (_videoController != null) {
      _videoController!.setVolume(volume);
    }
  }

  void toggleLooping() {
    setState(() => _isLooping = !_isLooping);
    if (_videoController != null) {
      _videoController!.setLooping(_isLooping);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Method to add text overlay
  void addTextOverlay({
    required String text,
    double fontSize = 24.0,
    Color color = Colors.white,
    String fontFamily = 'Roboto',
    bool isBold = false,
    bool isItalic = false,
    Duration? startTime,
    Duration? endTime,
  }) {
    final newItem = OverlayItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: OverlayType.text,
      position: Offset(_previewSize.width * 0.1, _previewSize.height * 0.1),
      fontSize: fontSize,
      color: color,
      fontFamily: fontFamily,
      isBold: isBold,
      isItalic: isItalic,
      rotation: 0.0,
      scale: 1.0,
      // Add timing properties for video overlays
      startTime: startTime ?? Duration.zero,
      endTime: endTime ?? _videoDuration,
    );

    setState(() {
      _overlayItems.add(newItem);
      _selectedItem = newItem;
      newItem.isSelected = true;
    });

    widget.onOverlaysChanged?.call(_overlayItems);
  }

  // Method to add sticker overlay
  void addStickerOverlay(String sticker) {
    final newItem = OverlayItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: sticker,
      type: OverlayType.sticker,
      position: Offset(_previewSize.width * 0.2, _previewSize.height * 0.2),
      fontSize: 48.0,
      rotation: 0.0, // Initialize with no rotation
      scale: 1.0, // Initialize with normal scale
    );

    setState(() {
      _overlayItems.add(newItem);
      _selectedItem = newItem;
      newItem.isSelected = true;
    });

    widget.onOverlaysChanged?.call(_overlayItems);
  }

  // Method to remove selected overlay
  void removeSelectedOverlay() {
    if (_selectedItem != null) {
      setState(() {
        _overlayItems.removeWhere((item) => item.id == _selectedItem!.id);
        _selectedItem = null;
      });
      widget.onOverlaysChanged?.call(_overlayItems);
    }
  }

  // Add method to get current video state for timeline synchronization
  Map<String, dynamic> getVideoState() {
    return {
      'currentPosition': _currentPosition,
      'duration': _videoDuration,
      'startTrim': _startTrim,
      'endTrim': _endTrim,
      'isPlaying': _isPlaying,
      'playbackSpeed': _playbackSpeed,
      'volume': _volume,
      'isLooping': _isLooping,
    };
  }

  // Method to apply trim and export trimmed video
  Future<String?> exportTrimmedVideo() async {
    if (!widget.isVideo ||
        _startTrim == Duration.zero && _endTrim == _videoDuration) {
      return widget.mediaPath; // No trimming needed
    }

    try {
      // This would integrate with your MediaEditorService
      final trimmedPath = await MediaEditorService.trimVideo(
        inputPath: widget.mediaPath,
        startTime: _startTrim,
        endTime: _endTrim,
      );

      return trimmedPath;
    } catch (e) {
      print('Error exporting trimmed video: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _previewSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Container(
          color: Colors.black,
          child: GestureDetector(
            onTap: () {
              // Deselect all items when tapping on empty space
              setState(() {
                _selectedItem = null;
                for (var item in _overlayItems) {
                  item.isSelected = false;
                }
              });
            },
            child: Stack(
              children: [
                // Media content
                (widget.isVideo || _isDynamicVideo)
                    ? _buildVideoPreview()
                    : _buildImagePreview(),

                // Video controls overlay (only for video)
                if ((widget.isVideo || _isDynamicVideo) && _isInitialized)
                  _buildVideoControls(),

                // Overlay items (filtered by time for videos)
                ..._getVisibleOverlays()
                    .map((item) => _buildDraggableOverlay(item)),

                // Delete button for selected item
                if (_selectedItem != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.red,
                      onPressed: removeSelectedOverlay,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ),

                // Video info overlay
                if ((widget.isVideo || _isDynamicVideo) && _isInitialized)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatDuration(_currentPosition)} / ${_formatDuration(_videoDuration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          if (_playbackSpeed != 1.0)
                            Text(
                              'Speed: ${_playbackSpeed}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          if (_isLooping)
                            const Text(
                              'Looping',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Get overlays that should be visible at current time (for video editing)
  List<OverlayItem> _getVisibleOverlays() {
    if (!widget.isVideo && !_isDynamicVideo) return _overlayItems;

    return _overlayItems.where((item) {
      final startTime = item.startTime ?? Duration.zero;
      final endTime = item.endTime ?? _videoDuration;
      return _currentPosition >= startTime && _currentPosition <= endTime;
    }).toList();
  }

  // Add getter for checking if it's currently a video (original or dynamic)
  bool get isCurrentlyVideo => widget.isVideo || _isDynamicVideo;

  Widget _buildVideoControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Skip to start
            IconButton(
              onPressed: () => seekToPosition(_startTrim),
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              tooltip: 'Go to start',
            ),

            // Play/Pause
            IconButton(
              onPressed: _togglePlayPause,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),

            // Skip to end
            IconButton(
              onPressed: () => seekToPosition(_endTrim),
              icon: const Icon(Icons.skip_next, color: Colors.white),
              tooltip: 'Go to end',
            ),

            // Loop toggle
            IconButton(
              onPressed: toggleLooping,
              icon: Icon(
                _isLooping ? Icons.repeat : Icons.repeat,
                color: _isLooping ? Colors.green : Colors.white,
              ),
              tooltip: 'Toggle loop',
            ),

            // Speed control
            PopupMenuButton<double>(
              icon: const Icon(Icons.speed, color: Colors.white),
              tooltip: 'Playback speed',
              onSelected: setPlaybackSpeed,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 0.25, child: Text('0.25x')),
                const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                const PopupMenuItem(value: 2.0, child: Text('2.0x')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_isInitialized) {
      return const Center(child: Loader());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  // Format duration to show actual timeline position
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildDraggableOverlay(OverlayItem item) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Deselect all items first
            for (var overlayItem in _overlayItems) {
              overlayItem.isSelected = false;
            }
            // Select this item
            item.isSelected = true;
            _selectedItem = item;
          });
        },
        onScaleStart: (details) {
          if (!item.isSelected) return;
          _initialScale = item.scale;
          _initialRotation = item.rotation;
          _initialFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) {
          if (!item.isSelected) return;

          setState(() {
            // Handle scaling (pinch to zoom)
            if (details.scale != 1.0) {
              final newScale = (_initialScale * details.scale).clamp(0.3, 4.0);
              item.scale = newScale;
            }

            // Handle rotation (twist gesture)
            if (details.rotation != 0.0) {
              item.rotation = _initialRotation + details.rotation;
            }

            // Handle translation during scaling
            final delta = details.focalPoint - _initialFocalPoint;
            final newX = (item.position.dx + delta.dx * 0.5)
                .clamp(0.0, _previewSize.width - 100);
            final newY = (item.position.dy + delta.dy * 0.5)
                .clamp(0.0, _previewSize.height - 50);
            item.position = Offset(newX, newY);
          });
          widget.onOverlaysChanged?.call(_overlayItems);
        },
        onScaleEnd: (details) {},
        child: Transform.rotate(
          angle: item.rotation,
          child: Transform.scale(
            scale: item.scale,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: item.isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildOverlayContent(item),
                  // Show control handles when selected
                  if (item.isSelected) ..._buildCapCutStyleControls(item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCapCutStyleControls(OverlayItem item) {
    const double handleSize = 24.0;
    const double handleOffset = 12.0;

    return [
      // Top-left corner: Rotation handle
      Positioned(
        top: -handleOffset,
        left: -handleOffset,
        child: GestureDetector(
          onPanStart: (details) {
            _initialRotation = item.rotation;
          },
          onPanUpdate: (details) {
            // Calculate rotation based on movement around the center
            final center = Offset(item.scale * 50, item.scale * 25);
            final startVector = details.localPosition - center;
            final angle = startVector.direction;

            setState(() {
              item.rotation = angle;
            });
            widget.onOverlaysChanged?.call(_overlayItems);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.rotate_right,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Top-right corner: Scale/resize handle
      Positioned(
        top: -handleOffset,
        right: -handleOffset,
        child: GestureDetector(
          onPanStart: (details) {
            _initialScale = item.scale;
            _initialFocalPoint = details.globalPosition;
          },
          onPanUpdate: (details) {
            // Calculate scale based on distance change
            final currentPoint = details.globalPosition;
            final initialDistance = _initialFocalPoint.distance;
            final currentDistance = currentPoint.distance;
            final scaleChange = currentDistance / initialDistance;

            setState(() {
              final newScale = (_initialScale * scaleChange).clamp(0.3, 4.0);
              item.scale = newScale;
            });
            widget.onOverlaysChanged?.call(_overlayItems);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.zoom_out_map,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Bottom-left corner: Additional rotation handle (for easier access)
      Positioned(
        bottom: -handleOffset,
        left: -handleOffset,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Simple rotation based on horizontal movement
              item.rotation += details.delta.dx * 0.02;
            });
            widget.onOverlaysChanged?.call(_overlayItems);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.refresh,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Bottom-right corner: Scale handle (alternative)
      Positioned(
        bottom: -handleOffset,
        right: -handleOffset,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Scale based on diagonal movement
              final delta = details.delta.dx + details.delta.dy;
              final scaleChange = 1.0 + (delta * 0.0003);
              final newScale = (item.scale * scaleChange).clamp(0.3, 4.0);
              item.scale = newScale;
            });
            widget.onOverlaysChanged?.call(_overlayItems);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.open_in_full,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Center delete button
      Positioned(
        top: -handleOffset * 2,
        right: 0,
        left: 0,
        child: Center(
          child: GestureDetector(
            onTap: removeSelectedOverlay,
            child: Container(
              width: handleSize,
              height: handleSize,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.delete,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildOverlayContent(OverlayItem item, {bool isDragging = false}) {
    Widget content;

    if (item.type == OverlayType.sticker) {
      content = Text(
        item.content,
        style: TextStyle(
          fontSize: item.fontSize,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      );
    } else {
      content = Text(
        item.content,
        style: GoogleFonts.getFont(
          item.fontFamily,
          fontSize: item.fontSize,
          color: item.color,
          fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: item.isItalic ? FontStyle.italic : FontStyle.normal,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.7),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: isDragging
          ? BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: content,
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Image.file(
        File(widget.mediaPath),
        fit: BoxFit.contain,
      ),
    );
  }

  // Getter for overlay items (for external access)
  List<OverlayItem> get overlayItems => _overlayItems;

  Duration get currentPosition => _currentPosition;
  Duration get videoDuration => _videoDuration;
  Duration get startTrim => _startTrim;
  Duration get endTrim => _endTrim;
  bool get isPlaying => _isPlaying;
  double get playbackSpeed => _playbackSpeed;
  double get volume => _volume;
  bool get isLooping => _isLooping;
}
