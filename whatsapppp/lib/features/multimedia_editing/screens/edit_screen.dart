import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:whatsapppp/common/utils/utils.dart';
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
  double _startValue = 0.0, _endValue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    await _trimmer.loadVideo(videoFile: File(widget.filePath));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return AlertDialog(
      title: const Text('Trim Video'),
      content: SizedBox(
        height: 250,
        child: Column(children: [
          VideoViewer(trimmer: _trimmer),
          const SizedBox(height: 12),
        ]),
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

  final _previewPanelKey = GlobalKey<PreviewPanelState>();
  final _toolTabs = ['Edit', 'Text', 'Audio', 'Effects', 'Filters'];
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
          IconButton(icon: const Icon(Icons.save), onPressed: _exportProject),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareProject),
        ],
      ),
      body: Column(children: [
        Expanded(
          flex: 3,
          child: PreviewPanel(
            key: _previewPanelKey,
            mediaPath: widget.mediaPath,
            isVideo: widget.isVideo,
            onOverlaysChanged: (overlays) => _currentOverlays = overlays,
          ),
        ),
        if (widget.isVideo) const Expanded(flex: 2, child: TimelineEditor()),
        _buildTabBar(),
        Expanded(flex: 2, child: _buildToolOptions()),
      ]),
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
              )),
            ),
            child: Text(_toolTabs[index],
                style: TextStyle(
                  color:
                      _selectedTabIndex == index ? Colors.blue : Colors.white,
                )),
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
            ('Speed', Icons.speed, _showSpeedDialog),
            ('Volume', Icons.volume_up, _showVideoVolumeDialog),
            ('Rotate', Icons.rotate_90_degrees_ccw, () => _rotateVideo(90)),
            ('Transform', Icons.transform, () {}), // To be implemented
            ('Animation', Icons.animation, () {}), // To be implemented
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
                      Text('Background Music',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                      Text('Original Audio',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                              backgroundColor: Colors.red),
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
                      Text('Voice Over',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                              backgroundColor: Colors.red),
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
                      Text('Advanced',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
      (splitPaths) {
        // Handle split video paths
        if (splitPaths.isNotEmpty) {
          setState(() => widget.mediaPath = splitPaths.first);
          showSnackBar(context, 'Video split into ${splitPaths.length} parts');
        }
      },
    );
  }

  void _showSpeedDialog() {
    if (!widget.isVideo) return;

    _videoHandler.showSpeedDialog(
      context,
      widget.mediaPath,
      (newPath) => setState(() => widget.mediaPath = newPath),
    );
  }

  void _rotateVideo(int degrees) {
    if (!widget.isVideo) return;

    _videoHandler.rotateVideo(
      context,
      widget.mediaPath,
      degrees,
      (newPath) => setState(() => widget.mediaPath = newPath),
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

  void _applyFilter(String? filter) {
    if (filter == null || filter == 'original') return;

    if (widget.isVideo) {
      MediaEditorService.applyFilter(
        mediaPath: widget.mediaPath,
        filterType: filter,
        isVideo: true,
      ).then((newPath) {
        setState(() => widget.mediaPath = newPath);
        showSnackBar(context, 'Filter "$filter" applied to video');
      });
    } else {
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
      // For video effects, use MediaEditorService
      MediaEditorService.applyFilter(
        mediaPath: widget.mediaPath,
        filterType: effect,
        isVideo: true,
      ).then((newPath) {
        setState(() => widget.mediaPath = newPath);
        showSnackBar(context, 'Effect "$effect" applied to video');
      });
    } else {
      // For image effects, use ImageHandler
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
      (newPath) => setState(() => widget.mediaPath = newPath),
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

  Widget _buildEffectTools() {
    final effects = [
      ('Blur', Icons.blur_on),
      ('Glow', Icons.brightness_high),
      ('Shadow', Icons.filter_hdr),
      ('3D', Icons.view_in_ar),
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

    return GridView.count(
      crossAxisCount: 3,
      children: filters
          .map((filter) => _filterButton(filter.$1, filter.$2, filter.$3))
          .toList(),
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

  Widget _filterButton(String name, String? filter, Color color) {
    return InkWell(
      onTap: () => _applyFilter(filter),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
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

  void _exportProject() async {
    final overlays = _previewPanelKey.currentState?.overlayItems ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Project'),
        content: Text('Ready to export with ${overlays.length} overlay items'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
