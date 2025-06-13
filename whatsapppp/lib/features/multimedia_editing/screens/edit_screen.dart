import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/common/widgets/emoji_stickers.dart';
import 'package:whatsapppp/features/multimedia_editing/controller/media_controller.dart';
import 'package:whatsapppp/features/multimedia_editing/function_handler/audio_handler.dart';
import 'package:whatsapppp/features/multimedia_editing/services/audio_service.dart';
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
              DurationRange(
                Duration(milliseconds: (_startValue * 1000).round()),
                Duration(milliseconds: (_endValue * 1000).round()),
              )),
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
  Color _selectedTextColor = Colors.white;
  double _textSize = 24.0;
  bool _isBold = false, _isItalic = false;
  String _selectedFont = 'Roboto';

  final _previewPanelKey = GlobalKey<PreviewPanelState>();
  final _toolTabs = ['Edit', 'Text', 'Audio', 'Effects', 'Filters'];
  final _availableFonts = ['Roboto', 'Lobster', 'Pacifico'];
  List<OverlayItem> _currentOverlays = [];

  late final AudioHandler _audioHandler;

  @override
  void initState() {
    super.initState();
    _media = ref.read(mediaControllerProvider);
    _audioHandler = AudioHandler();
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioHandler.dispose();
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
            ('Volume', Icons.volume_up, () {}),
            ('Rotate', Icons.rotate_90_degrees_ccw, () => _rotateVideo(90)),
            ('Transform', Icons.transform, () {}),
            ('Animation', Icons.animation, () {}),
            ('Duplicate', Icons.copy, () {}),
          ]
        : [
            ('Crop', Icons.crop, _cropImage),
            ('Rotate', Icons.rotate_90_degrees_ccw, () => _rotateImage(90)),
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

  // Simplified dialog methods
  Future<void> _showTextEditor() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.text_fields, color: Colors.blue),
            SizedBox(width: 8),
            Text('Add Text'),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
                child: Column(children: [
              // Text input
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type your text here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Font dropdown
              DropdownButtonFormField<String>(
                value: _selectedFont,
                decoration: const InputDecoration(labelText: 'Font Family'),
                items: _availableFonts
                    .map((font) => DropdownMenuItem(
                          value: font,
                          child: Text(font, style: GoogleFonts.getFont(font)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedFont = value!),
              ),
              const SizedBox(height: 16),

              // Size slider
              Text('Size: ${_textSize.round()}px'),
              Slider(
                value: _textSize,
                min: 12.0,
                max: 80.0,
                onChanged: (value) => setState(() => _textSize = value),
              ),

              // Style checkboxes
              Row(children: [
                Checkbox(
                  value: _isBold,
                  onChanged: (v) => setState(() => _isBold = v!),
                ),
                const Text('Bold'),
                Checkbox(
                  value: _isItalic,
                  onChanged: (v) => setState(() => _isItalic = v!),
                ),
                const Text('Italic'),
              ]),

              // Color picker
              Wrap(
                children: [
                  Colors.white,
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green
                ]
                    .map(
                      (color) => GestureDetector(
                        onTap: () => setState(() => _selectedTextColor = color),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedTextColor == color
                                  ? Colors.blue
                                  : Colors.grey,
                              width: _selectedTextColor == color ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // Preview
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _textController.text.isEmpty
                      ? 'Preview'
                      : _textController.text,
                  style: GoogleFonts.getFont(
                    _selectedFont,
                    fontSize: _textSize,
                    color: _selectedTextColor,
                    fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ])),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  _addTextToPreview();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStickerPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Sticker'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6),
            itemCount: emojiStickers.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _addStickerToPreview(emojiStickers[index]);
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    emojiStickers[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Simplified handlers
  Future<void> _cropImage() async {
    final cropped = await MediaEditorService.cropImage(widget.mediaPath);
    if (cropped != null) {
      setState(() => widget.mediaPath = cropped.path);
      showSnackBar(context, 'Image cropped');
    }
  }

  Future<void> _applyFilter(String? filter) async {
    if (filter == null) return;
    final newPath = await MediaEditorService.applyFilter(
      mediaPath: widget.mediaPath,
      filterType: filter,
      isVideo: widget.isVideo,
    );
    setState(() => widget.mediaPath = newPath);
  }

  Future<void> _rotateImage(int degrees) async {
    final newPath = await MediaEditorService.rotateMedia(
      mediaPath: widget.mediaPath,
      degrees: degrees,
      isVideo: false,
    );
    setState(() => widget.mediaPath = newPath);
    showSnackBar(context, 'Image rotated');
  }

  Future<void> _rotateVideo(int degrees) async {
    final output = '${widget.mediaPath}_rotated.mp4';
    final transpose = {
      90: 'transpose=1',
      180: 'transpose=2,transpose=2',
      270: 'transpose=2'
    }[degrees];
    await FFmpegKit.execute('-i ${widget.mediaPath} -vf "$transpose" $output');
    _media.setCurrentMediaFile(File(output));
    setState(() => widget.mediaPath = output);
  }

  Future<void> _changeVideoSpeed(double speedFactor) async {
    final newPath = await MediaEditorService.changeVideoSpeed(
      videoPath: widget.mediaPath,
      speedFactor: speedFactor,
    );
    setState(() => widget.mediaPath = newPath);
    showSnackBar(context, 'Speed changed successfully!');
  }

  Future<void> _showSplitDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split Video'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Split at (seconds)'),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      await _splitVideo(Duration(seconds: result));
    }
  }

  Future<void> _showSpeedDialog() async {
    double speed = 1.0;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Video Speed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Speed: ${speed.toStringAsFixed(2)}x'),
              Slider(
                value: speed,
                min: 0.25,
                max: 2.0,
                divisions: 7,
                onChanged: (value) => setState(() => speed = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, speed),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result > 0) await _changeVideoSpeed(result);
  }

  Future<void> _splitVideo(Duration splitPoint) async {
    final input = widget.mediaPath;
    final firstHalf = '${input}_part1.mp4';
    final secondHalf = '${input}_part2.mp4';

    await FFmpegKit.execute(
        '-i $input -t ${splitPoint.inSeconds} -c copy $firstHalf');

    await FFmpegKit.execute(
        '-i $input -ss ${splitPoint.inSeconds} -c copy $secondHalf');

    showSnackBar(context, 'Video split into two parts.');
  }

  void _addTextToPreview() {
    _previewPanelKey.currentState?.addTextOverlay(
      text: _textController.text,
      fontSize: _textSize,
      color: _selectedTextColor,
      fontFamily: _selectedFont,
      isBold: _isBold,
      isItalic: _isItalic,
    );
    _textController.clear();
    showSnackBar(
        context, 'Text added! You can now drag it around the preview.');
  }

  void _addStickerToPreview(String sticker) {
    _previewPanelKey.currentState?.addStickerOverlay(sticker);
    showSnackBar(
      context,
      'Sticker added! You can now drag it around the preview.',
    );
  }

  void _addVoiceOver() {/* implement recording UI */}
  void _applyEffect(String effect) {
    /* implement FFmpeg effect via controller */
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

  void _shareProject() {/* implement share via controller */}
}
