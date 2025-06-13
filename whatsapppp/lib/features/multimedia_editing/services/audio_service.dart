import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Add background music to video
  static Future<String?> addBackgroundMusicToVideo({
    required String videoPath,
    required String audioPath,
    double audioVolume = 0.5,
    double videoVolume = 1.0,
    bool loopAudio = false,
  }) async {
    try {
      final outputPath = '${videoPath}_with_music.mp4';

      // Build FFmpeg command for mixing audio
      String command;

      if (loopAudio) {
        // Loop the audio to match video duration
        command = '-i "$videoPath" -stream_loop -1 -i "$audioPath" '
            '-filter_complex "[0:a]volume=$videoVolume[a0];[1:a]volume=$audioVolume[a1];[a0][a1]amix=inputs=2:duration=first:dropout_transition=0[out]" '
            '-map 0:v -map "[out]" -c:v copy -c:a aac -shortest "$outputPath"';
      } else {
        // Use audio as-is (may be shorter or longer than video)
        command = '-i "$videoPath" -i "$audioPath" '
            '-filter_complex "[0:a]volume=$videoVolume[a0];[1:a]volume=$audioVolume[a1];[a0][a1]amix=inputs=2:duration=longest:dropout_transition=0[out]" '
            '-map 0:v -map "[out]" -c:v copy -c:a aac "$outputPath"';
      }

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('Failed to add background music');
        return null;
      }
    } catch (e) {
      print('Error adding background music: $e');
      return null;
    }
  }

  // Mute original audio from video
  static Future<String?> muteOriginalAudio(String videoPath) async {
    try {
      final outputPath = '${videoPath}_muted.mp4';

      // Remove audio track completely
      final command = '-i "$videoPath" -c:v copy -an "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('Failed to mute original audio');
        return null;
      }
    } catch (e) {
      print('Error muting original audio: $e');
      return null;
    }
  }

  // Adjust original audio volume
  static Future<String?> adjustOriginalAudioVolume({
    required String videoPath,
    required double
        volumeLevel, // 0.0 to 2.0 (0 = mute, 1 = original, 2 = double)
  }) async {
    try {
      final outputPath = '${videoPath}_volume_adjusted.mp4';

      final command =
          '-i "$videoPath" -filter:a "volume=$volumeLevel" -c:v copy -c:a aac "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('Failed to adjust audio volume');
        return null;
      }
    } catch (e) {
      print('Error adjusting audio volume: $e');
      return null;
    }
  }

  // Add voice over to video
  static Future<String?> addVoiceOverToVideo({
    required String videoPath,
    required String voiceOverPath,
    double voiceVolume = 1.0,
    double originalVolume = 0.3, // Lower original audio when adding voice over
  }) async {
    try {
      final outputPath = '${videoPath}_with_voiceover.mp4';

      final command = '-i "$videoPath" -i "$voiceOverPath" '
          '-filter_complex "[0:a]volume=$originalVolume[a0];[1:a]volume=$voiceVolume[a1];[a0][a1]amix=inputs=2:duration=first:dropout_transition=0[out]" '
          '-map 0:v -map "[out]" -c:v copy -c:a aac "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('Failed to add voice over');
        return null;
      }
    } catch (e) {
      print('Error adding voice over: $e');
      return null;
    }
  }

  // Record voice over
  static Future<String?> recordVoiceOver({
    required BuildContext context,
    int maxDurationSeconds = 300, // 5 minutes max
  }) async {
    try {
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return null;
      }

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final recordingPath = '${tempDir.path}/voiceover_$timestamp.m4a';

      // Show recording dialog
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => VoiceRecordingDialog(
          outputPath: recordingPath,
          maxDurationSeconds: maxDurationSeconds,
        ),
      );
    } catch (e) {
      print('Error recording voice over: $e');
      return null;
    }
  }

  // Pick audio file from device
  static Future<String?> pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }
      return null;
    } catch (e) {
      print('Error picking audio file: $e');
      return null;
    }
  }

  // Preview audio file
  static Future<void> previewAudio(String audioPath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(audioPath));
    } catch (e) {
      print('Error playing audio preview: $e');
    }
  }

  // Stop audio preview
  static Future<void> stopAudioPreview() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio preview: $e');
    }
  }

  // Get audio duration
  static Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      await _audioPlayer.setSource(DeviceFileSource(audioPath));
      return await _audioPlayer.getDuration();
    } catch (e) {
      print('Error getting audio duration: $e');
      return null;
    }
  }

  // Trim audio file
  static Future<String?> trimAudio({
    required String audioPath,
    required Duration startTime,
    required Duration endTime,
  }) async {
    try {
      final outputPath = '${audioPath}_trimmed.m4a';

      final command = '-i "$audioPath" -ss ${startTime.inSeconds} '
          '-t ${(endTime - startTime).inSeconds} -c copy "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('Failed to trim audio');
        return null;
      }
    } catch (e) {
      print('Error trimming audio: $e');
      return null;
    }
  }

  // Extract audio from video
  static Future<String?> extractAudioFromVideo(String videoPath) async {
    try {
      final outputPath = '${videoPath}_audio.m4a';

      final command = '-i "$videoPath" -vn -c:a copy "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('Failed to extract audio');
        return null;
      }
    } catch (e) {
      print('Error extracting audio: $e');
      return null;
    }
  }

  // Fade in/out audio
  static Future<String?> addAudioFade({
    required String audioPath,
    double fadeInDuration = 2.0,
    double fadeOutDuration = 2.0,
  }) async {
    try {
      final outputPath = '${audioPath}_faded.m4a';

      final command =
          '-i "$audioPath" -af "afade=t=in:ss=0:d=$fadeInDuration,afade=t=out:st=${fadeInDuration}:d=$fadeOutDuration" "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        print('Failed to add audio fade');
        return null;
      }
    } catch (e) {
      print('Error adding audio fade: $e');
      return null;
    }
  }
}

// Voice Recording Dialog Widget
class VoiceRecordingDialog extends StatefulWidget {
  final String outputPath;
  final int maxDurationSeconds;

  const VoiceRecordingDialog({
    super.key,
    required this.outputPath,
    required this.maxDurationSeconds,
  });

  @override
  State<VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<VoiceRecordingDialog>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  int _recordingDuration = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: widget.outputPath,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });

        _animationController.repeat(reverse: true);
        _startTimer();
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });
      _animationController.stop();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration++;
        });
        if (_recordingDuration < widget.maxDurationSeconds) {
          _startTimer();
        } else {
          _stopRecording();
        }
      }
    });
  }

  Future<void> _playRecording() async {
    try {
      if (_hasRecording) {
        await _player.play(DeviceFileSource(widget.outputPath));
        setState(() => _isPlaying = true);

        _player.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        });
      }
    } catch (e) {
      print('Error playing recording: $e');
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _player.stop();
      setState(() => _isPlaying = false);
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.mic, color: Colors.red),
          SizedBox(width: 8),
          Text('Voice Recording'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording duration
          Text(
            _formatDuration(_recordingDuration),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 24),

          // Recording button
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording ? _scaleAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.red.shade300,
                      boxShadow: [
                        if (_isRecording)
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Text(
            _isRecording ? 'Tap to stop recording' : 'Tap to start recording',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),

          if (_hasRecording) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isPlaying ? _stopPlaying : _playRecording,
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Stop' : 'Preview'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasRecording = false;
                      _recordingDuration = 0;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        if (_hasRecording)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, widget.outputPath),
            child: const Text('Use Recording'),
          ),
      ],
    );
  }
}
