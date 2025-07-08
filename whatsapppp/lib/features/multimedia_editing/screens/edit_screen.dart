import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/multimedia_editing/controller/media_controller.dart';
import 'package:whatsapppp/features/multimedia_editing/function_handler/audio_handler.dart';
import 'package:whatsapppp/features/multimedia_editing/function_handler/image_handler.dart';
import 'package:whatsapppp/features/multimedia_editing/function_handler/text_handler.dart';
import 'package:whatsapppp/features/multimedia_editing/function_handler/video_handler.dart';
import 'package:whatsapppp/features/multimedia_editing/services/media_editor_service.dart';
import 'package:whatsapppp/features/multimedia_editing/widgets/preview_panel.dart';
import 'package:whatsapppp/features/multimedia_editing/widgets/timeline_editor.dart';

// TrimmerDialog - Simplified
class TrimmerDialog extends StatefulWidget {
  final String filePath;
  const TrimmerDialog({Key? key, required this.filePath}) : super(key: key);

  @override
  _TrimmerDialogState createState() => _TrimmerDialogState();
}

class _TrimmerDialogState extends State<TrimmerDialog> {
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isLoading = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      await _trimmer.loadVideo(videoFile: File(widget.filePath));
      final videoDuration =
          await _trimmer.videoPlayerController!.value.duration;
      setState(() {
        _isLoading = false;
        _endValue = videoDuration.inMilliseconds.toDouble();
      });
    } catch (e) {
      print('Error loading video: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _trimmer.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: Loader());

    return AlertDialog(
      title: const Text('Trim Video'),
      content: SizedBox(
        height: 400,
        width: double.maxFinite,
        child: Column(
          children: [
            // Video Preview
            Expanded(
              child: VideoViewer(trimmer: _trimmer),
            ),

            const SizedBox(height: 16),

            // Timeline Trimmer
            Container(
              height: 60,
              child: TrimViewer(
                trimmer: _trimmer,
                viewerHeight: 60,
                viewerWidth: MediaQuery.of(context).size.width,
                onChangeStart: (value) => setState(() => _startValue = value),
                onChangeEnd: (value) => setState(() => _endValue = value),
                onChangePlaybackState: (value) =>
                    setState(() => _isPlaying = value),
              ),
            ),

            const SizedBox(height: 16),

            // Time display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Start: ${_formatDuration(Duration(milliseconds: _startValue.round()))}'),
                Text(
                    'End: ${_formatDuration(Duration(milliseconds: _endValue.round()))}'),
              ],
            ),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    await _trimmer.videoPlayerController!.seekTo(
                      Duration(milliseconds: _startValue.round()),
                    );
                  },
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  onPressed: () async {
                    if (_isPlaying) {
                      await _trimmer.videoPlayerController!.pause();
                    } else {
                      await _trimmer.videoPlayerController!.play();
                    }
                    setState(() => _isPlaying = !_isPlaying);
                  },
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  onPressed: () async {
                    await _trimmer.videoPlayerController!.seekTo(
                      Duration(milliseconds: _endValue.round()),
                    );
                  },
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            {
              'start': Duration(milliseconds: (_startValue * 1000).round()),
              'end': Duration(milliseconds: (_endValue * 1000).round()),
            },
          ),
          child: const Text('Trim'),
        ),
      ],
    );
  }
}

// Main EditScreen - Significantly reduced
// ignore: must_be_immutable
class EditScreen extends ConsumerStatefulWidget {
  String mediaPath;
  final bool isVideo;

  EditScreen({
    required this.mediaPath,
    required this.isVideo,
  });

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  late final MediaController _media;
  int _selectedTabIndex = 0;

  // Text editing properties - consolidated
  final _textController = TextEditingController();

  final GlobalKey<PreviewPanelState> _previewPanelKey =
      GlobalKey<PreviewPanelState>();
  final _toolTabs = ['Edit', 'Text', 'Audio', 'Effects', 'Filters'];
  // ignore: unused_field
  List<OverlayItem> _currentOverlays = [];

  // Handler instances
  late final AudioHandler _audioHandler;
  late final TextHandler _textHandler;
  late final VideoHandler _videoHandler;
  late final ImageHandler _imageHandler;

  @override
  void initState() {
    super.initState();
    _media = ref.read(mediaControllerProvider);
    // Initialize handlers
    _audioHandler = AudioHandler();
    _textHandler = TextHandler();
    _videoHandler = VideoHandler();
    _imageHandler = ImageHandler();
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioHandler.dispose();
    _textHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVideo ? 'Video Editor' : 'Photo Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _exportProject,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProject,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: PreviewPanel(
              key: _previewPanelKey,
              mediaPath: widget.mediaPath,
              isVideo: widget.isVideo,
              onOverlaysChanged: (overlays) => _currentOverlays = overlays,
            ),
          ),

          // Updated TimelineEditor with proper integration
          if (widget.isVideo) ...[
            Expanded(
              flex: 2,
              child: TimelineEditor(
                videoPath: widget.mediaPath,
                onTrimChanged: (start, end) {
                  // Connect timeline trim changes to preview panel
                  _previewPanelKey.currentState?.setTrimRange(start, end);
                },
                onPlay: () {
                  // Connect timeline play to preview panel
                  _previewPanelKey.currentState?.playVideo();
                },
                onPause: () {
                  // Connect timeline pause to preview panel
                  _previewPanelKey.currentState?.pauseVideo();
                },
                onSeek: (position) {
                  // Connect timeline seeking to preview panel
                  _previewPanelKey.currentState?.seekToPosition(position);
                },
              ),
            ),
          ],

          _buildTabBar(),
          Expanded(flex: 2, child: _buildToolOptions()),
        ],
      ),
      floatingActionButton: _buildSaveButton(),
    );
  }

  Widget _buildSaveButton() {
    return FloatingActionButton(
      onPressed: () async {
        if (!widget.isVideo) {
          await _saveEditedImageToCloud();
        } else {
          await _saveEditedVideoToCloud();
        }
      },
      tooltip: widget.isVideo ? 'Save Video' : 'Save Image',
      child: const Icon(Icons.save),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      color: Colors.grey[900],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _toolTabs.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () => setState(() => _selectedTabIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 3,
                  color: _selectedTabIndex == index
                      ? Colors.blue
                      : Colors.transparent,
                ),
              ),
            ),
            child: Text(
              _toolTabs[index],
              style: TextStyle(
                color: _selectedTabIndex == index ? Colors.blue : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolOptions() {
    switch (_toolTabs[_selectedTabIndex]) {
      case 'Edit':
        return _buildEditTools();
      case 'Text':
        return _buildTextTools();
      case 'Audio':
        return _buildAudioTools();
      case 'Effects':
        return _buildEffectTools();
      case 'Filters':
        return _buildFilterTools();
      default:
        return Container();
    }
  }

  Widget _buildEditTools() {
    final tools = widget.isVideo
        ? [
            ('Split', Icons.cut, _showSplitDialog),
            ('Volume', Icons.volume_up, _showVideoVolumeDialog),
            ('Duplicate', Icons.copy, _duplicateVideo),
          ]
        : [
            ('Crop', Icons.crop, _cropImage),
            ('Rotate', Icons.rotate_90_degrees_ccw, () => _rotateImage(90)),
            ('Duplicate', Icons.copy, _duplicateImage),
          ];

    return GridView.count(
      crossAxisCount: 4,
      children: tools
          .map((tool) => _toolButton(tool.$2, tool.$1, onTap: tool.$3))
          .toList(),
    );
  }

  Widget _buildTextTools() {
    return Column(children: [
      ListTile(
        leading: const Icon(Icons.text_fields),
        title: const Text('Add Text'),
        onTap: _showTextEditor,
      ),
      ListTile(
        leading: const Icon(Icons.emoji_emotions),
        title: const Text('Stickers'),
        onTap: _showStickerPicker,
      ),
    ]);
  }

  Widget _buildAudioTools() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Background Music Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.music_note, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Background Music',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addBackgroundMusic,
                          icon: const Icon(Icons.library_music),
                          label: const Text('Choose Music'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _previewSelectedMusic,
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Preview Music',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Original Audio Controls
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.volume_up, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Original Audio',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _muteOriginalAudio,
                          icon: const Icon(Icons.volume_off),
                          label: const Text('Mute'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showVolumeAdjustDialog,
                          icon: const Icon(Icons.tune),
                          label: const Text('Adjust Volume'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Voice Over Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mic, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Voice Over',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _recordVoiceOver,
                          icon: const Icon(Icons.mic),
                          label: const Text('Record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _importVoiceOver,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Import'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Advanced Audio Tools
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Advanced',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _extractAudio,
                        icon: const Icon(Icons.audio_file),
                        label: const Text('Extract Audio'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAudioFadeDialog,
                        icon: const Icon(Icons.gradient),
                        label: const Text('Fade In/Out'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAudioTrimDialog,
                        icon: const Icon(Icons.content_cut),
                        label: const Text('Trim Audio'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectTools() {
    final effects = [
      ('Blur', Icons.blur_on),
      ('Brighten', Icons.brightness_high),
      ('Darken', Icons.filter_hdr),
      ('Contrast', Icons.view_in_ar),
    ];

    return GridView.count(
      crossAxisCount: 3,
      children:
          effects.map((effect) => _effectButton(effect.$1, effect.$2)).toList(),
    );
  }

  Widget _buildFilterTools() {
    final filters = [
      ('Original', null, Colors.transparent),
      ('Vintage', 'vintage', Colors.orange.withOpacity(0.3)),
      ('B&W', 'grayscale', Colors.grey),
      ('Sepia', 'sepia', Colors.brown.withOpacity(0.3)),
      ('Vibrant', 'vibrant', Colors.purple.withOpacity(0.3)),
      ('Cool', 'cool', Colors.blue.withOpacity(0.3)),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filters.length,
      itemBuilder: (context, index) {
        final filter = filters[index];
        return InkWell(
          onTap: () {
            if (filter.$2 != null) {
              _applyFilter(filter.$2!);
            }
            //  _filterButton(filter.$1, filter.$2, filter.$3);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: filter.$3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: filter.$2 == 'original'
                    ? const Icon(Icons.image, size: 20)
                    : Container(),
              ),
              const SizedBox(height: 4),
              Text(
                filter.$1,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolButton(IconData icon, String label,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }

  Widget _effectButton(String name, IconData icon) {
    return InkWell(
      onTap: () => _applyEffect(name.toLowerCase()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }

  void _showTextEditor() {
    _textHandler.showTextEditor(
      context,
      (text, fontSize, color, fontFamily, isBold, isItalic) {
        // Add text overlay to preview panel
        _previewPanelKey.currentState?.addTextOverlay(
          text: text,
          fontSize: fontSize,
          color: color,
          fontFamily: fontFamily,
          isBold: isBold,
          isItalic: isItalic,
        );
      },
    );
  }

  void _showStickerPicker() {
    _textHandler.showStickerPicker(
      context,
      (sticker) {
        // Add sticker overlay to preview panel
        _previewPanelKey.currentState?.addStickerOverlay(sticker);
      },
    );
  }

  void _showSplitDialog() {
    if (!widget.isVideo) return;

    _videoHandler.showSplitDialog(
      context,
      widget.mediaPath,
      (splitPaths, originalSplitPoint) {
        // Added originalSplitPoint parameter
        if (splitPaths.isNotEmpty) {
          setState(() {
            widget.mediaPath =
                splitPaths[1]; // Use second part (from split point to end)
          });

          // Update preview panel with split video and original timeline offset
          if (_previewPanelKey.currentState != null) {
            _previewPanelKey.currentState!.handleVideoSplit(
              splitPaths[1], // New video path (second part)
              originalSplitPoint, // Original split point from the full video
            );
          }

          // Update timeline editor with split information
          final timelineKey = GlobalKey<TimelineEditorState>();
          // You'll need to add this key to TimelineEditor
          if (timelineKey.currentState != null) {
            timelineKey.currentState!.updateForSplitVideo(
              originalSplitPoint,
              Duration
                  .zero, // New duration will be calculated from the split video
            );
          }

          showSnackBar(context, 'Video split successfully');
        }
      },
    );
  }

  void _rotateImage(int degrees) {
    if (widget.isVideo) return;

    _imageHandler.rotateImage(
      context,
      widget.mediaPath,
      degrees,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _cropImage() {
    if (widget.isVideo) return;

    _imageHandler.showCropDialog(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _applyFilter(String filter) {
    if (filter == 'original') return;

    if (widget.isVideo) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Applying filter to video...'),
            ],
          ),
        ),
      );

      MediaEditorService.applyFilter(
        mediaPath: widget.mediaPath,
        filterType: filter,
        isVideo: true,
      ).then((newPath) {
        Navigator.pop(context); // Close loading dialog
        setState(() {
          widget.mediaPath = newPath;
        });
        showSnackBar(context, 'Filter "$filter" applied to video');
      }).catchError((error) {
        Navigator.pop(context); // Close loading dialog
        showSnackBar(context, 'Error applying filter: $error');
        print('Video filter error: $error'); // For debugging
      });
    } else {
      // Use ImageHandler method for images
      _imageHandler.applyFilter(
        context,
        widget.mediaPath,
        filter,
        (newPath) => setState(() => widget.mediaPath = newPath),
      );
    }
  }

  void _applyEffect(String effect) {
    if (widget.isVideo) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Applying effect to video...'),
            ],
          ),
        ),
      );

      MediaEditorService.applyEffect(
        mediaPath: widget.mediaPath,
        effectType: effect,
        isVideo: true,
      ).then((newPath) {
        Navigator.pop(context); // Close loading dialog
        setState(() {
          widget.mediaPath = newPath;
        });
        showSnackBar(context, 'Effect "$effect" applied to video');
      }).catchError((error) {
        Navigator.pop(context); // Close loading dialog
        showSnackBar(context, 'Error applying effect: $error');
        print('Video effect error: $error'); // For debugging
      });
    } else {
      // Use ImageHandler method for images
      _imageHandler.applyEffect(
        context,
        widget.mediaPath,
        effect,
        (newPath) => setState(() => widget.mediaPath = newPath),
      );
    }
  }

  void _shareProject() async {
    try {
      // Export with overlays first if any exist
      final overlays = _previewPanelKey.currentState?.overlayItems ?? [];

      if (overlays.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Processing overlays...'),
              ],
            ),
          ),
        );

        // Here you would implement overlay rendering
        // For now, just show success
        Navigator.pop(context);
      }

      // Use system share functionality
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Project'),
          content: Text('Share ${widget.isVideo ? 'video' : 'image'} file?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement actual sharing logic here
                showSnackBar(
                    context, 'Sharing functionality to be implemented');
              },
              child: const Text('Share'),
            ),
          ],
        ),
      );
    } catch (e) {
      showSnackBar(context, 'Error sharing project: $e');
    }
  }

  // Add missing volume and duplicate methods for video
  void _showVideoVolumeDialog() {
    if (!widget.isVideo) return;

    _videoHandler.showVolumeDialog(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _duplicateVideo() {
    if (!widget.isVideo) return;

    _videoHandler.duplicateVideo(
      context,
      widget.mediaPath,
      (newPath) {
        // Optionally switch to duplicated file or show info
        setState(() {
          widget.mediaPath = newPath;
        });
        showSnackBar(context, 'Video duplicated successfully');
      },
    );
  }

  void _duplicateImage() {
    if (widget.isVideo) return;

    _imageHandler.duplicateImage(
      context,
      widget.mediaPath,
      (newPath) {
        setState(() {
          widget.mediaPath = newPath;
        });
        showSnackBar(context, 'Image duplicated successfully');
      },
    );
  }

  void _addBackgroundMusic() async {
    await _audioHandler.addBackgroundMusic(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _previewSelectedMusic() async {
    await _audioHandler.previewSelectedMusic(context);
  }

  void _muteOriginalAudio() async {
    await _audioHandler.muteOriginalAudio(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _showVolumeAdjustDialog() async {
    await _audioHandler.showVolumeAdjustDialog(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _recordVoiceOver() async {
    await _audioHandler.recordVoiceOver(
      context,
      widget.mediaPath,
      (newPath) {
        setState(() => widget.mediaPath = newPath);
        // ADDED: Update preview panel when media path changes
        _previewPanelKey.currentState?.updateMediaPath(newPath);
      },
    );
  }

  void _importVoiceOver() async {
    await _audioHandler.importVoiceOver(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _extractAudio() async {
    await _audioHandler.extractAudio(context, widget.mediaPath);
  }

  void _showAudioFadeDialog() async {
    await _audioHandler.showAudioFadeDialog(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _showAudioTrimDialog() async {
    await _audioHandler.showAudioTrimDialog(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _exportProject() async {
    try {
      final overlays = _previewPanelKey.currentState?.overlayItems ?? [];

      if (!widget.isVideo) {
        // For images, always use the new save method
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to export image with ${overlays.length} overlay items',
                ),
                const SizedBox(height: 16),
                const Text('Choose export option:'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save to Cloud'),
              ),
            ],
          ),
        );

        if (shouldSave == true) {
          await _saveEditedImageToCloud();
        }
      } else {
        // Original video export logic
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Project'),
            content:
                Text('Ready to export with ${overlays.length} overlay items'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      showSnackBar(context, 'Error exporting project: $e');
    }
  }

  Future<void> _saveEditedImageToCloud() async {
    try {
      final overlays = _previewPanelKey.currentState?.overlayItems ?? [];

      // Show saving indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving image to cloud...'),
            ],
          ),
        ),
      );

      Navigator.pop(context);

      // Use the updated method that handles overlays and blob storage
      final blobId = await _media.saveCurrentEditedImage(
        context: context,
        projectId: widget.mediaPath.hashCode.toString(),
        originalImagePath: widget.mediaPath, // Pass the original path
        overlays: overlays, // Pass the overlays
      );

      if (blobId != null) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Image Saved Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Your edited image with ${overlays.length} overlays has been saved as blob.',
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Blob ID: $blobId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareProject();
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showSnackBar(context, 'Failed to save image: $e');
    }
  }

  // In edit_screen.dart
  Future<void> _saveEditedVideoToCloud() async {
    try {
      final videoFile = File(widget.mediaPath);

      // Show saving indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving video to cloud...'),
            ],
          ),
        ),
      );

      Navigator.pop(context);

      final blobId =
          await ref.read(mediaControllerProvider).saveEditedVideoToBlob(
                videoFile: videoFile,
                context: context,
                originalFileName: videoFile.path.split('/').last,
              );

      // Dismiss saving indicator
      Navigator.pop(context);

      if (blobId != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Video Saved Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                const Text('Your edited video has been saved as blob.'),
                const SizedBox(height: 8),
                SelectableText(
                  'Blob ID: $blobId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareProject();
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss saving indicator
      showSnackBar(context, 'Failed to save video: $e');
    }
  }
}
