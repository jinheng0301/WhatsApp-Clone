import 'package:flutter/material.dart';
import 'package:whatsapppp/features/multimedia_editing/services/audio_service.dart';

class VoiceOverPreviewController extends StatefulWidget {
  final Map<String, dynamic> mediaFile;
  final String blobId;

  const VoiceOverPreviewController({
    super.key,
    required this.mediaFile,
    required this.blobId,
  });

  @override
  State<VoiceOverPreviewController> createState() =>
      _VoiceOverPreviewControllerState();
}

class _VoiceOverPreviewControllerState
    extends State<VoiceOverPreviewController> {
  bool _isPlaying = false;
  double _currentPosition = 0.0;
  double _totalDuration = 1.0;

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _playVoiceOver();
    } else {
      _pauseVoiceOver();
    }
  }

  void _stopPlayback() {
    setState(() {
      _isPlaying = false;
      _currentPosition = 0.0;
    });
    AudioService.stopAudioPreview();
  }

  void _playVoiceOver() {
    try {
      final voiceOverPath = widget.mediaFile['voiceOverPath'] as String?;
      if (voiceOverPath != null) {
        AudioService.previewAudio(voiceOverPath);
      }
    } catch (e) {
      print('Error playing voice-over: $e');
    }
  }

  void _pauseVoiceOver() {
    AudioService.stopAudioPreview();
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.mic, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Voice-Over',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _togglePlayback,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: _stopPlayback,
              icon: const Icon(
                Icons.stop,
                color: Colors.white,
              ),
            ),
          ],
        ),
        // Progress bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.purple,
            inactiveTrackColor: Colors.grey[600],
            thumbColor: Colors.purple,
            overlayColor: Colors.purple.withOpacity(0.2),
            trackHeight: 2.0,
          ),
          child: Slider(
            value: _currentPosition,
            min: 0.0,
            max: _totalDuration,
            onChanged: (value) {
              setState(() {
                _currentPosition = value;
              });
            },
          ),
        ),
        // Duration text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_currentPosition),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              _formatDuration(_totalDuration),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
