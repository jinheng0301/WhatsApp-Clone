import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/multimedia_editing/services/media_editor_service.dart';

class VideoHandler {
  Future<void> showTrimDialog(
    BuildContext context,
    String videoPath,
    Function(String newPath) onVideoTrimmed,
  ) async {
    final result = await showDialog<DurationRange>(
      context: context,
      builder: (context) => TrimmerDialog(filePath: videoPath),
    );

    if (result != null) {
      final trimmedPath = await _trimVideo(videoPath, result);
      if (trimmedPath != null) {
        onVideoTrimmed(trimmedPath);
        showSnackBar(context, 'Video trimmed successfully!');
      }
    }
  }

  Future<String?> _trimVideo(String videoPath, DurationRange range) async {
    try {
      final outputPath = '${videoPath}_trimmed.mp4';
      final startSeconds = range.start.inMilliseconds / 1000;
      final durationSeconds =
          (range.end.inMilliseconds - range.start.inMilliseconds) / 1000;

      final command =
          '-i "$videoPath" -ss $startSeconds -t $durationSeconds -c copy "$outputPath"';
      await FFmpegKit.execute(command);

      return outputPath;
    } catch (e) {
      print('Error trimming video: $e');
      return null;
    }
  }

  Future<void> showSplitDialog(
    BuildContext context,
    String videoPath,
    Function(List<String> splitPaths, Duration originalSplitPoint)
        onVideoSplit, // Added originalSplitPoint parameter
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Split at (seconds)',
                hintText: 'Enter time in seconds',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will create two separate video files',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final seconds = int.tryParse(controller.text);
              if (seconds != null && seconds > 0) {
                Navigator.pop(context, seconds);
              }
            },
            child: const Text('Split'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      final splitPoint = Duration(seconds: result);
      final splitPaths = await MediaEditorService.splitVideo(
        videoPath: videoPath,
        splitPoint: splitPoint,
      );
      onVideoSplit(splitPaths, splitPoint); // Pass the original split point
      showSnackBar(context, 'Video split into ${splitPaths.length} parts');
    }
  }

  Future<void> showSpeedDialog(
    BuildContext context,
    String videoPath,
    Function(String newPath) onSpeedChanged,
  ) async {
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
              const SizedBox(height: 16),
              Slider(
                value: speed,
                min: 0.25,
                max: 2.0,
                divisions: 7,
                onChanged: (value) => setState(() => speed = value),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => setState(() => speed = 0.5),
                    child: const Text('0.5x'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => speed = 1.0),
                    child: const Text('1x'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => speed = 1.5),
                    child: const Text('1.5x'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => speed = 2.0),
                    child: const Text('2x'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, speed),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result > 0) {
      final newPath = await MediaEditorService.changeVideoSpeed(
        videoPath: videoPath,
        speedFactor: result,
      );
      onSpeedChanged(newPath);
      showSnackBar(context, 'Speed changed to ${result.toStringAsFixed(2)}x');
    }
  }

  Future<void> rotateVideo(
    BuildContext context,
    String videoPath,
    int degrees,
    Function(String newPath) onVideoRotated,
  ) async {
    final newPath = await MediaEditorService.rotateMedia(
      mediaPath: videoPath,
      degrees: degrees,
      isVideo: true,
    );
    onVideoRotated(newPath);
    showSnackBar(context, 'Video rotated ${degrees}°');
  }

  Future<void> showVolumeDialog(
    BuildContext context,
    String videoPath,
    Function(String newPath) onVolumeAdjusted,
  ) async {
    double volume = 1.0;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adjust Volume'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Volume: ${(volume * 100).round()}%'),
              const SizedBox(height: 16),
              Slider(
                value: volume,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: (value) => setState(() => volume = value),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => setState(() => volume = 0.0),
                    child: const Text('Mute'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => volume = 0.5),
                    child: const Text('50%'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => volume = 1.0),
                    child: const Text('100%'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => volume = 1.5),
                    child: const Text('150%'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, volume),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final newPath = await MediaEditorService.adjustOriginalAudioVolume(
        videoPath: videoPath,
        volumeLevel: result,
      );
      if (newPath != null) {
        onVolumeAdjusted(newPath);
        showSnackBar(context, 'Volume adjusted to ${(result * 100).round()}%');
      }
    }
  }

  Future<void> duplicateVideo(
    BuildContext context,
    String videoPath,
    Function(String newPath) onVideoDuplicated,
  ) async {
    try {
      // Check if the original file exists
      final originalFile = File(videoPath);
      if (!await originalFile.exists()) {
        showSnackBar(context, 'Original video file not found');
        return;
      }

      // Get file info
      final directory = originalFile.parent;
      final fileName = originalFile.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      final nameWithoutExtension = fileName.replaceAll('.$extension', '');

      // Generate unique filename
      String outputPath;
      int counter = 1;
      do {
        outputPath =
            '${directory.path}/${nameWithoutExtension}_copy_$counter.$extension';
        counter++;
      } while (await File(outputPath).exists());

      // Show progress dialog for large video files
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Duplicating video...'),
            ],
          ),
        ),
      );

      // Copy the file
      await originalFile.copy(outputPath);

      // Close progress dialog
      Navigator.of(context).pop();

      // Verify the copy was created successfully
      final copiedFile = File(outputPath);
      if (await copiedFile.exists()) {
        onVideoDuplicated(outputPath);
        showSnackBar(context,
            'Video duplicated successfully!\nSaved as: ${outputPath.split('/').last}');
      } else {
        showSnackBar(context, 'Failed to create duplicate video');
      }
    } catch (e) {
      // Close progress dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      showSnackBar(context, 'Error duplicating video: $e');
      print('Duplicate video error: $e'); // For debugging
    }
  }

  Future<void> addTransition(
    BuildContext context,
    String videoPath,
    String transitionType,
    Function(String newPath) onTransitionAdded,
  ) async {
    try {
      final outputPath = '${videoPath}_transition.mp4';
      String filter = '';

      switch (transitionType) {
        case 'fade_in':
          filter = 'fade=in:0:30';
          break;
        case 'fade_out':
          filter = 'fade=out:st=0:d=2';
          break;
        case 'slide_left':
          filter = 'slide=direction=left';
          break;
        case 'slide_right':
          filter = 'slide=direction=right';
          break;
        default:
          filter = 'fade=in:0:30';
      }

      final command = '-i "$videoPath" -vf "$filter" "$outputPath"';
      await FFmpegKit.execute(command);

      onTransitionAdded(outputPath);
      showSnackBar(context, 'Transition added successfully!');
    } catch (e) {
      showSnackBar(context, 'Error adding transition: $e');
    }
  }
}

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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
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

class DurationRange {
  final Duration start;
  final Duration end;

  DurationRange(this.start, this.end);
}
