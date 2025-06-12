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

  EditScreen({Key? key, required this.mediaPath, required this.isVideo})
      : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _media = ref.read(mediaControllerProvider);
  }

  @override
  void dispose() {
    _textController.dispose();
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

  String? _selectedMusicPath;
  String? _recordedVoiceOverPath;
  bool _isPreviewingAudio = false;

  Future<void> _addBackgroundMusic() async {
    try {
      final musicPath = await AudioService.pickAudioFile();
      if (musicPath != null) {
        setState(() => _selectedMusicPath = musicPath);

        // Show music configuration dialog
        await _showMusicConfigDialog(musicPath);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error selecting music: $e');
      }
    }
  }

  Future<void> _showMusicConfigDialog(String musicPath) async {
    double audioVolume = 0.5;
    double videoVolume = 1.0;
    bool loopAudio = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.music_note, color: Colors.blue),
              SizedBox(width: 8),
              Text('Music Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Music Volume: ${(audioVolume * 100).round()}%'),
              Slider(
                value: audioVolume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) => setState(() => audioVolume = value),
              ),
              const SizedBox(height: 16),
              Text('Original Audio Volume: ${(videoVolume * 100).round()}%'),
              Slider(
                value: videoVolume,
                min: 0.0,
                max: 2.0,
                onChanged: (value) => setState(() => videoVolume = value),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Loop Music'),
                value: loopAudio,
                onChanged: (value) =>
                    setState(() => loopAudio = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'audioVolume': audioVolume,
                'videoVolume': videoVolume,
                'loopAudio': loopAudio,
              }),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _applyBackgroundMusic(
        musicPath,
        result['audioVolume'],
        result['videoVolume'],
        result['loopAudio'],
      );
    }
  }

  Future<void> _applyBackgroundMusic(
    String musicPath,
    double audioVolume,
    double videoVolume,
    bool loopAudio,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding background music...'),
            ],
          ),
        ),
      );

      final newPath = await AudioService.addBackgroundMusicToVideo(
        videoPath: widget.mediaPath,
        audioPath: musicPath,
        audioVolume: audioVolume,
        videoVolume: videoVolume,
        loopAudio: loopAudio,
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (newPath != null) {
        setState(() => widget.mediaPath = newPath);
        if (mounted) {
          showSnackBar(context, 'Background music added successfully!');
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'Failed to add background music');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showSnackBar(context, 'Error adding background music: $e');
      }
    }
  }

  Future<void> _previewSelectedMusic() async {
    if (_selectedMusicPath == null) {
      showSnackBar(context, 'Please select music first');
      return;
    }

    try {
      if (_isPreviewingAudio) {
        await AudioService.stopAudioPreview();
        setState(() => _isPreviewingAudio = false);
      } else {
        await AudioService.previewAudio(_selectedMusicPath!);
        setState(() => _isPreviewingAudio = true);

        // Auto-stop after 30 seconds preview
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && _isPreviewingAudio) {
            AudioService.stopAudioPreview();
            setState(() => _isPreviewingAudio = false);
          }
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error previewing music: $e');
    }
  }

  Future<void> _muteOriginalAudio() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Muting original audio...'),
            ],
          ),
        ),
      );

      final newPath = await AudioService.muteOriginalAudio(widget.mediaPath);

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (newPath != null) {
        setState(() => widget.mediaPath = newPath);
        if (mounted) {
          showSnackBar(context, 'Original audio muted successfully!');
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'Failed to mute original audio');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error muting audio: $e');
      }
    }
  }

  Future<void> _showVolumeAdjustDialog() async {
    double currentVolume = 1.0;

    final result = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.volume_up, color: Colors.green),
              SizedBox(width: 8),
              Text('Adjust Volume'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Volume: ${(currentVolume * 100).round()}%'),
              const SizedBox(height: 16),
              Slider(
                value: currentVolume,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                label: '${(currentVolume * 100).round()}%',
                onChanged: (value) => setState(() => currentVolume = value),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => setState(() => currentVolume = 0.0),
                    child: const Text('Mute'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => currentVolume = 1.0),
                    child: const Text('Reset'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => currentVolume = 2.0),
                    child: const Text('Max'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, currentVolume),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _applyVolumeAdjustment(result);
    }
  }

  Future<void> _applyVolumeAdjustment(double volumeLevel) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adjusting volume...'),
            ],
          ),
        ),
      );

      final newPath = await AudioService.adjustOriginalAudioVolume(
        videoPath: widget.mediaPath,
        volumeLevel: volumeLevel,
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (newPath != null) {
        setState(() => widget.mediaPath = newPath);
        if (mounted) {
          showSnackBar(context, 'Volume adjusted successfully!');
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'Failed to adjust volume');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error adjusting volume: $e');
      }
    }
  }

  Future<void> _recordVoiceOver() async {
    try {
      final recordedPath = await AudioService.recordVoiceOver(
        context: context,
        maxDurationSeconds: 300, // 5 minutes max
      );

      if (recordedPath != null) {
        setState(() => _recordedVoiceOverPath = recordedPath);

        // Show dialog to configure voice over
        await _showVoiceOverConfigDialog(recordedPath);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error recording voice over: $e');
      }
    }
  }

  Future<void> _showVoiceOverConfigDialog(String voiceOverPath) async {
    double voiceVolume = 1.0;
    double originalVolume = 0.3; // Lower original audio when adding voice over

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic, color: Colors.purple),
              SizedBox(width: 8),
              Text('Voice Over Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voice Volume: ${(voiceVolume * 100).round()}%'),
              Slider(
                value: voiceVolume,
                min: 0.0,
                max: 2.0,
                onChanged: (value) => setState(() => voiceVolume = value),
              ),
              const SizedBox(height: 16),
              Text('Original Audio Volume: ${(originalVolume * 100).round()}%'),
              Slider(
                value: originalVolume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) => setState(() => originalVolume = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await AudioService.previewAudio(voiceOverPath);
                        } catch (e) {
                          if (context.mounted) {
                            showSnackBar(context, 'Error previewing: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Preview'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await AudioService.stopAudioPreview();
                      },
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'voiceVolume': voiceVolume,
                'originalVolume': originalVolume,
              }),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _applyVoiceOver(
        voiceOverPath,
        result['voiceVolume'],
        result['originalVolume'],
      );
    }
  }

  Future<void> _applyVoiceOver(
    String voiceOverPath,
    double voiceVolume,
    double originalVolume,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding voice over...'),
            ],
          ),
        ),
      );

      final newPath = await AudioService.addVoiceOverToVideo(
        videoPath: widget.mediaPath,
        voiceOverPath: voiceOverPath,
        voiceVolume: voiceVolume,
        originalVolume: originalVolume,
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (newPath != null) {
        setState(() => widget.mediaPath = newPath);
        if (mounted) {
          showSnackBar(context, 'Voice over added successfully!');
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'Failed to add voice over');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error adding voice over: $e');
      }
    }
  }

  Future<void> _importVoiceOver() async {
    try {
      final voiceOverPath = await AudioService.pickAudioFile();
      if (voiceOverPath != null) {
        setState(() => _recordedVoiceOverPath = voiceOverPath);

        // Show configuration dialog
        await _showVoiceOverConfigDialog(voiceOverPath);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error importing voice over: $e');
      }
    }
  }

  Future<void> _extractAudio() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Extracting audio...'),
            ],
          ),
        ),
      );

      final audioPath =
          await AudioService.extractAudioFromVideo(widget.mediaPath);

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (audioPath != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.audio_file, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Audio Extracted'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Audio has been extracted successfully!'),
                  const SizedBox(height: 16),
                  Text('Saved to: ${audioPath.split('/').last}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await AudioService.previewAudio(audioPath);
                    } catch (e) {
                      if (context.mounted) {
                        showSnackBar(context, 'Error playing audio: $e');
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'Failed to extract audio');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error extracting audio: $e');
      }
    }
  }

  Future<void> _showAudioFadeDialog() async {
    double fadeInDuration = 2.0;
    double fadeOutDuration = 2.0;

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.gradient, color: Colors.blue),
              SizedBox(width: 8),
              Text('Audio Fade'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fade In Duration: ${fadeInDuration.toStringAsFixed(1)}s'),
              Slider(
                value: fadeInDuration,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                onChanged: (value) => setState(() => fadeInDuration = value),
              ),
              const SizedBox(height: 16),
              Text('Fade Out Duration: ${fadeOutDuration.toStringAsFixed(1)}s'),
              Slider(
                value: fadeOutDuration,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                onChanged: (value) => setState(() => fadeOutDuration = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'fadeIn': fadeInDuration,
                'fadeOut': fadeOutDuration,
              }),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _applyAudioFade(result['fadeIn']!, result['fadeOut']!);
    }
  }

  Future<void> _applyAudioFade(
      double fadeInDuration, double fadeOutDuration) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Applying audio fade...'),
            ],
          ),
        ),
      );

      // First extract audio, apply fade, then merge back
      final audioPath =
          await AudioService.extractAudioFromVideo(widget.mediaPath);
      if (audioPath == null) throw Exception('Failed to extract audio');

      final fadedAudioPath = await AudioService.addAudioFade(
        audioPath: audioPath,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
      );

      if (fadedAudioPath == null) throw Exception('Failed to apply fade');

      // Replace audio in video
      final newVideoPath =
          await _replaceAudioInVideo(widget.mediaPath, fadedAudioPath);

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (newVideoPath != null) {
        setState(() => widget.mediaPath = newVideoPath);
        if (mounted) {
          showSnackBar(context, 'Audio fade applied successfully!');
        }
      } else {
        throw Exception('Failed to replace audio in video');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error applying audio fade: $e');
      }
    }
  }

  Future<String?> _replaceAudioInVideo(
      String videoPath, String audioPath) async {
    try {
      final outputPath = '${videoPath}_with_faded_audio.mp4';

      // Use FFmpeg to replace audio in video
      final command =
          '-i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        return null;
      }
    } catch (e) {
      print('Error replacing audio in video: $e');
      return null;
    }
  }

  Future<void> _showAudioTrimDialog() async {
    double startTime = 0.0;
    double endTime = 30.0; // Default 30 seconds

    // Get actual audio/video duration if possible
    final duration = await AudioService.getAudioDuration(widget.mediaPath);
    if (duration != null) {
      endTime = duration.inSeconds.toDouble();
    }

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.content_cut, color: Colors.orange),
              SizedBox(width: 8),
              Text('Trim Audio'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start Time: ${startTime.toStringAsFixed(1)}s'),
              Slider(
                value: startTime,
                min: 0.0,
                max: endTime - 1,
                onChanged: (value) => setState(() => startTime = value),
              ),
              const SizedBox(height: 16),
              Text('End Time: ${endTime.toStringAsFixed(1)}s'),
              Slider(
                value: endTime,
                min: startTime + 1,
                max: duration?.inSeconds.toDouble() ?? 300.0,
                onChanged: (value) => setState(() => endTime = value),
              ),
              const SizedBox(height: 16),
              Text('Duration: ${(endTime - startTime).toStringAsFixed(1)}s'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'start': startTime,
                'end': endTime,
              }),
              child: const Text('Trim'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _applyAudioTrim(result['start']!, result['end']!);
    }
  }

  Future<void> _applyAudioTrim(double startTime, double endTime) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Trimming audio...'),
            ],
          ),
        ),
      );

      final trimmedPath = await AudioService.trimAudio(
        audioPath: widget.mediaPath,
        startTime: Duration(seconds: startTime.round()),
        endTime: Duration(seconds: endTime.round()),
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (trimmedPath != null) {
        setState(() => widget.mediaPath = trimmedPath);
        if (mounted) {
          showSnackBar(context, 'Audio trimmed successfully!');
        }
      } else {
        if (mounted) {
          showSnackBar(context, 'Failed to trim audio');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error trimming audio: $e');
      }
    }
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
        context, 'Sticker added! You can now drag it around the preview.');
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
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void _shareProject() {/* implement share via controller */}
}
