import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:whatsapppp/common/utils/utils.dart';
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
    'Audio',
    'Text',
    'Effects',
    'Filters'
  ];

  @override
  void initState() {
    super.initState();
    _media = ref.read(mediaControllerProvider);
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
              mediaPath: widget.mediaPath,
              isVideo: widget.isVideo,
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
      case 'Audio':
        return _buildAudioTools();
      case 'Text':
        return _buildTextTools();
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
          _toolButton(Icons.text_fields, 'Text', onTap: _showTextEditor),
          _toolButton(
            Icons.emoji_emotions,
            'Stickers',
            onTap: _showStickerPicker,
          ),
        ],
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

  Widget _buildTextTools() {
    return Column(
      children: [
        ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Add Text'),
            onTap: _showTextEditor),
        ListTile(
            leading: const Icon(Icons.emoji_emotions),
            title: const Text('Stickers'),
            onTap: _showStickerPicker),
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

  void _showTextEditor() {/* implement text editor */}

  void _showStickerPicker() {/* implement stickers */}

  void _applyEffect(String effect) {
    /* implement FFmpeg effect via controller */
  }

  void _exportProject() {
    // implement project export via controller
  }
  void _shareProject() {
    // implement share via controller
  }
}
