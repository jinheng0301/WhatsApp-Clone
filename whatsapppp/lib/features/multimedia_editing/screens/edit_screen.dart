import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/common/widgets/emoji_stickers.dart';
import 'package:whatsapppp/features/multimedia_editing/controller/media_controller.dart';
import 'package:whatsapppp/features/multimedia_editing/widgets/preview_panel.dart';
import 'package:whatsapppp/features/multimedia_editing/widgets/timeline_editor.dart';

// TrimmerDialog for video trimming
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
        child: Column(
          children: [
            VideoViewer(trimmer: _trimmer),
            const SizedBox(height: 12),
            // TrimEditor(
            //   trimmer: _trimmer,
            //   viewerHeight: 50,
            //   viewerWidth: MediaQuery.of(context).size.width * 0.8,
            //   maxVideoLength: const Duration(minutes: 5),
            //   onChangeStart: (v) => _startValue = v,
            //   onChangeEnd: (v) => _endValue = v,
            //   durationStyle: DurationStyle.FORMAT_MM_SS,
            // ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              DurationRange(
                Duration(milliseconds: (_startValue * 1000).round()),
                Duration(milliseconds: (_endValue * 1000).round()),
              ),
            );
          },
          child: const Text('Trim'),
        ),
      ],
    );
  }
}

// EditScreen widget
// ignore: must_be_immutable
class EditScreen extends ConsumerStatefulWidget {
  String mediaPath;
  final bool isVideo;

  EditScreen({Key? key, required this.mediaPath, required this.isVideo})
      : super(key: key);

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  late final MediaController _media;
  int _selectedTabIndex = 0;
  Rect? _lastCropRect;
  Size? _lastOriginalSize;
  final List<String> _toolTabs = [
    'Edit',
    'Text',
    'Audio',
    'Effects',
    'Filters'
  ];

  TextEditingController _textController = TextEditingController();
  Color _selectedTextColor = Colors.white;
  double _textSize = 24.0;
  bool _isBold = false;
  bool _isItalic = false;
  String _selectedFont = 'Roboto'; // Default font
  final List<String> availableFonts = [
    'Roboto',
    'Lobster',
    'Pacifico',
  ];

  // Reference to the PreviewPanel
  final GlobalKey<PreviewPanelState> _previewPanelKey =
      GlobalKey<PreviewPanelState>();
  List<OverlayItem> _currentOverlays = [];

  @override
  void initState() {
    super.initState();
    _media = ref.read(mediaControllerProvider);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _textController.dispose();
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
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: PreviewPanel(
              key: _previewPanelKey,
              mediaPath: widget.mediaPath,
              isVideo: widget.isVideo,
              onOverlaysChanged: (overlays) {
                _currentOverlays = overlays;
              },
            ),
          ),
          if (widget.isVideo) ...[
            const Expanded(
              flex: 2,
              child: TimelineEditor(),
            ),
          ],
          Container(
            height: 50,
            color: Colors.grey[900],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _toolTabs.length,
              itemBuilder: (context, index) {
                return InkWell(
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
                        color: _selectedTabIndex == index
                            ? Colors.blue
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(flex: 2, child: _buildToolOptions()),
        ],
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
    return GridView.count(
      crossAxisCount: 4,
      children: [
        if (widget.isVideo) ...[
          _toolButton(Icons.cut, 'Split', onTap: _showSplitDialog),
          _toolButton(Icons.speed, 'Speed', onTap: _showSpeedDialog),
          _toolButton(Icons.volume_up, 'Volume', onTap: () {}),
          _toolButton(
            Icons.rotate_90_degrees_ccw,
            'Rotate',
            onTap: () => _rotateVideo(90),
          ),
          _toolButton(Icons.transform, 'Transform', onTap: () {}),
          _toolButton(Icons.animation, 'Animation', onTap: () {}),
          _toolButton(Icons.copy, 'Duplicate', onTap: () {}),
        ] else ...[
          _toolButton(Icons.crop, 'Crop', onTap: _cropImage),
          _toolButton(Icons.filter, 'Filter', onTap: _applyGrayscaleFilter),
          _toolButton(
            Icons.rotate_90_degrees_ccw,
            'Rotate',
            onTap: () => _rotateImage(90),
          )
        ],
      ],
    );
  }

  Widget _buildTextTools() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildAudioTools() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.music_note),
          title: const Text('Add Music'),
          onTap: _addBackgroundMusic,
        ),
        ListTile(
          leading: const Icon(Icons.volume_off),
          title: const Text('Mute Original'),
          onTap: _muteOriginalAudio,
        ),
        ListTile(
          leading: const Icon(Icons.mic),
          title: const Text('Voice Over'),
          onTap: _addVoiceOver,
        ),
      ],
    );
  }

  Widget _buildEffectTools() {
    return GridView.count(
      crossAxisCount: 3,
      children: [
        _effectButton('Blur', Icons.blur_on),
        _effectButton('Glow', Icons.brightness_high),
        _effectButton('Shadow', Icons.filter_hdr),
        _effectButton('3D', Icons.view_in_ar),
      ],
    );
  }

  Widget _buildFilterTools() {
    return GridView.count(
      crossAxisCount: 3,
      children: [
        _filterButton('Original', null),
        _filterButton('Vintage', 'vintage'),
        _filterButton('B&W', 'grayscale'),
        _filterButton('Sepia', 'sepia'),
        _filterButton('Vibrant', 'vibrant'),
        _filterButton('Cool', 'cool'),
      ],
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

  Widget _filterButton(String name, String? filter) {
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
                color: _getFilterColor(filter),
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

  Color _getFilterColor(String? filter) {
    switch (filter) {
      case 'vintage':
        return Colors.orange.withOpacity(0.3);
      case 'grayscale':
        return Colors.grey;
      case 'sepia':
        return Colors.brown.withOpacity(0.3);
      case 'vibrant':
        return Colors.purple.withOpacity(0.3);
      case 'cool':
        return Colors.blue.withOpacity(0.3);
      default:
        return Colors.transparent;
    }
  }

  // Handlers
  Future<void> _cropImage() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: widget.mediaPath,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop'),
        IOSUiSettings(title: 'Crop')
      ],
    );
    if (cropped != null) {
      _media.setCurrentMediaFile(File(cropped.path));
      setState(() => widget.mediaPath = cropped.path);
      showSnackBar(context, 'Image cropped');
    }
  }

  Future<void> _applyFilter(String? filter) async {
    if (filter == null) return;
    if (!widget.isVideo) {
      await _media.applyImageFilter(
          imageFile: File(widget.mediaPath),
          filterType: filter,
          context: context);
    } else {
      await _media.applyVideoFilter(
          videoFile: File(widget.mediaPath),
          filterType: filter,
          context: context);
    }
  }

  Future<void> _applyGrayscaleFilter() async {
    final output = '${widget.mediaPath}_gray.mp4';
    await FFmpegKit.execute('-i ${widget.mediaPath} -vf format=gray $output');
    _media.setCurrentMediaFile(File(output));
    setState(() => widget.mediaPath = output);
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

  Future<void> _showSplitDialog() async {
    // Show a simple dialog to enter split seconds
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
            onPressed: () {
              final seconds = int.tryParse(controller.text);
              Navigator.of(context).pop(seconds);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      await _splitVideo(Duration(seconds: result));
    }
  }

  Future<void> _changeVideoSpeed(double speedFactor) async {
    final outputPath = '${widget.mediaPath}_speed.mp4';
    final command =
        '-i ${widget.mediaPath} -filter_complex "[0:v]setpts=${1 / speedFactor}*PTS[v];[0:a]atempo=$speedFactor[a]" -map "[v]" -map "[a]" $outputPath';

    await FFmpegKit.execute(command);
    _media.setCurrentMediaFile(File(outputPath));
    setState(() => widget.mediaPath = outputPath);

    showSnackBar(context, 'Speed changed successfully!');
  }

  Future<void> _showSpeedDialog() async {
    double speed = 1.0;
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Video Speed'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select speed:'),
                  Slider(
                    value: speed,
                    min: 0.25,
                    max: 2.0,
                    divisions: 7,
                    label: speed.toStringAsFixed(2),
                    onChanged: (value) => setState(() => speed = value),
                  ),
                  Text('${speed.toStringAsFixed(2)}x'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(speed),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result != null && result > 0) {
      await _changeVideoSpeed(result);
    }
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

  Future<void> _rotateImage(int degrees) async {
    final file = File(widget.mediaPath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final rotated = img.copyRotate(image, angle: degrees);
    final output = '${widget.mediaPath}_rotated.jpg';
    await File(output).writeAsBytes(img.encodeJpg(rotated));

    _media.setCurrentMediaFile(File(output));
    setState(() => widget.mediaPath = output);
    showSnackBar(context, 'Image rotated');
  }

  Future<void> _trimVideo() async {
    if (!widget.isVideo) return;
    final range = await showDialog<DurationRange>(
      context: context,
      builder: (_) => TrimmerDialog(filePath: widget.mediaPath),
    );
    if (range != null) {
      await _media.trimVideo(
        videoFile: File(widget.mediaPath),
        startTime: range.start,
        endTime: range.end,
        context: context,
      );
      showSnackBar(context, 'Video trimmed successfully!');
    }
  }

  void _addBackgroundMusic() => _media.addAudioToVideo(
        videoFile: File(widget.mediaPath),
        audioFile: File(''),
        context: context,
      );

  void _muteOriginalAudio() => _media.applyVideoFilter(
        videoFile: File(widget.mediaPath),
        filterType: 'mute',
        context: context,
      );

  void _addVoiceOver() {/* implement recording UI */}

  void _showTextEditor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.text_fields, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Add Text'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.7,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Text input field with enhanced styling
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Type your text here...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          maxLines: 3,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Font selection with preview
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedFont,
                          decoration: const InputDecoration(
                            labelText: 'Font Family',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            prefixIcon: Icon(Icons.font_download),
                          ),
                          items: availableFonts.map((font) {
                            return DropdownMenuItem(
                              value: font,
                              child: Text(
                                font,
                                style: GoogleFonts.getFont(font, fontSize: 16),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedFont = value!);
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Text size with visual indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.format_size),
                                const SizedBox(width: 8),
                                const Text('Text Size'),
                                const Spacer(),
                                Text('${_textSize.round()}px'),
                              ],
                            ),
                            Slider(
                              value: _textSize,
                              min: 12.0,
                              max: 80.0,
                              divisions: 68,
                              activeColor: Colors.blue,
                              onChanged: (value) {
                                setState(() => _textSize = value);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Text styling options with better UI
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Text Style',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('Bold'),
                                    value: _isBold,
                                    onChanged: (value) {
                                      setState(() => _isBold = value!);
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('Italic'),
                                    value: _isItalic,
                                    onChanged: (value) {
                                      setState(() => _isItalic = value!);
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Color picker with preset colors
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Text Color',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),

                            // Quick color options
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Colors.white,
                                Colors.black,
                                Colors.red,
                                Colors.blue,
                                Colors.green,
                                Colors.yellow,
                                Colors.purple,
                                Colors.orange,
                              ]
                                  .map((color) => GestureDetector(
                                        onTap: () {
                                          setState(
                                              () => _selectedTextColor = color);
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _selectedTextColor == color
                                                  ? Colors.blue
                                                  : Colors.grey,
                                              width: _selectedTextColor == color
                                                  ? 3
                                                  : 1,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),

                            const SizedBox(height: 12),

                            // Custom color picker button
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Pick Custom Color'),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: _selectedTextColor,
                                          onColorChanged: (color) {
                                            setState(() =>
                                                _selectedTextColor = color);
                                          },
                                          enableAlpha: false,
                                          displayThumbColor: true,
                                          showLabel: true,
                                          paletteType: PaletteType.hsvWithHue,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Done'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.palette),
                              label: const Text('Custom Color'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _selectedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Text preview with better styling
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            _textController.text.isEmpty
                                ? 'Preview text will appear here'
                                : _textController.text,
                            style: GoogleFonts.getFont(
                              availableFonts.contains(_selectedFont)
                                  ? _selectedFont
                                  : 'Roboto',
                              fontSize: _textSize,
                              color: _selectedTextColor,
                              fontWeight:
                                  _isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle: _isItalic
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _addTextToPreview();
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Text'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Updated method to add text directly to preview panel
  void _addTextToPreview() {
    final previewPanelState = _previewPanelKey.currentState;
    if (previewPanelState != null) {
      previewPanelState.addTextOverlay(
        text: _textController.text,
        fontSize: _textSize,
        color: _selectedTextColor,
        fontFamily: _selectedFont,
        isBold: _isBold,
        isItalic: _isItalic,
      );
    }

    // Clear the text controller
    _textController.clear();

    showSnackBar(
      context,
      'Text added! You can now drag it around the preview.',
    );
  }

  void _showStickerPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.emoji_emotions, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Choose Sticker'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              children: [
                // Search/filter bar (if needed)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Tap any sticker to add it to your media',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),

                // Sticker grid with enhanced styling
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: emojiStickers.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _addStickerToPreview(emojiStickers[index]);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              emojiStickers[index],
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ],
        );
      },
    );
  }

// Method to add sticker to media
  void _addStickerToPreview(String sticker) {
    final previewPanelState = _previewPanelKey.currentState;
    if (previewPanelState != null) {
      previewPanelState.addStickerOverlay(sticker);
    }

    showSnackBar(
        context, 'Sticker added! You can now drag it around the preview.');
  }

  void _applyEffect(String effect) {
    /* implement FFmpeg effect via controller */
  }

  // Updated export method to include overlay information
  void _exportProject() async {
    // Get current overlays from preview panel
    final previewPanelState = _previewPanelKey.currentState;
    if (previewPanelState != null) {
      final overlays = previewPanelState.overlayItems;

      // Here you would implement the actual export logic
      // For now, just show the overlay information
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Project'),
          content:
              Text('Ready to export with ${overlays.length} overlay items'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _shareProject() {
    // implement share via controller
  }
}
