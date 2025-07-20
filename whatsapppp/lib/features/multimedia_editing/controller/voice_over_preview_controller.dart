import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isLoading = false;
  double _currentPosition = 0.0;
  double _totalDuration = 1.0;
  String? _currentVoiceOverPath;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _loadVoiceOverPath();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = position.inSeconds.toDouble();
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration.inSeconds.toDouble();
        });
      }
    });

    // Listen for completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = 0.0;
        });
      }
    });
  }

  void _loadVoiceOverPath() {
    // Try multiple possible paths and formats
    _currentVoiceOverPath = widget.mediaFile['voiceOverPath'] as String? ??
        widget.mediaFile['audioPath'] as String? ??
        widget.mediaFile['voiceOverUrl'] as String? ??
        widget.mediaFile['blobPath'] as String?; // Try blob path as fallback

    print('🎤 Loading voice-over path:');
    print('   - voiceOverPath: ${widget.mediaFile['voiceOverPath']}');
    print('   - audioPath: ${widget.mediaFile['audioPath']}');
    print('   - voiceOverUrl: ${widget.mediaFile['voiceOverUrl']}');
    print('   - blobPath: ${widget.mediaFile['blobPath']}');
    print('   - Final path: $_currentVoiceOverPath');

    if (_currentVoiceOverPath != null) {
      _loadAudioDuration();
    } else {
      print('❌ No valid voice-over path found in media file');
      print('   Available keys: ${widget.mediaFile.keys.toList()}');
    }
  }

  Future<void> _loadAudioDuration() async {
    if (_currentVoiceOverPath == null) {
      print('❌ Cannot load audio: path is null');
      return;
    }

    try {
      setState(() => _isLoading = true);
      print('🎵 Attempting to load audio from: $_currentVoiceOverPath');

      // Try different source types based on path format
      Source audioSource;
      if (_currentVoiceOverPath!.startsWith('http')) {
        audioSource = UrlSource(_currentVoiceOverPath!);
        print('   Using UrlSource for HTTP path');
      } else if (_currentVoiceOverPath!.startsWith('/')) {
        audioSource = DeviceFileSource(_currentVoiceOverPath!);
        print('   Using DeviceFileSource for local path');
      } else {
        // Assume it's a relative path or asset
        audioSource = AssetSource(_currentVoiceOverPath!);
        print('   Using AssetSource for relative path');
      }

      await _audioPlayer.setSource(audioSource);
      final duration = await _audioPlayer.getDuration();

      if (mounted && duration != null) {
        setState(() {
          _totalDuration = duration.inSeconds.toDouble();
          _isLoading = false;
        });
        print('✅ Audio loaded successfully, duration: ${duration.inSeconds}s');
      } else {
        print('❌ Could not get audio duration');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('💥 Error loading audio duration: $e');
      print('   Path: $_currentVoiceOverPath');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_currentVoiceOverPath == null) {
      _showError('Voice-over path not found');
      print('❌ Cannot play: voice-over path is null');
      return;
    }

    try {
      print('🎵 Toggle playback - current state: isPlaying=$_isPlaying');

      if (_isPlaying) {
        await _audioPlayer.pause();
        print('⏸️ Audio paused');
      } else {
        if (_currentPosition == 0.0) {
          print('▶️ Starting audio playback from beginning');

          // Determine source type again for playback
          Source audioSource;
          if (_currentVoiceOverPath!.startsWith('http')) {
            audioSource = UrlSource(_currentVoiceOverPath!);
          } else if (_currentVoiceOverPath!.startsWith('/')) {
            audioSource = DeviceFileSource(_currentVoiceOverPath!);
          } else {
            audioSource = AssetSource(_currentVoiceOverPath!);
          }

          await _audioPlayer.play(audioSource);
        } else {
          print('▶️ Resuming audio playback');
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print('💥 Error toggling playback: $e');
      print('   Path: $_currentVoiceOverPath');
      _showError('Error playing voice-over: ${e.toString()}');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentPosition = 0.0;
      });
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  Future<void> _seekTo(double seconds) async {
    try {
      await _audioPlayer.seek(Duration(seconds: seconds.toInt()));
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '00:00';

    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingWidget() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.mic, color: Colors.purple, size: 20),
            SizedBox(width: 8),
            Text(
              'Loading Voice-Over...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.mic_off, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Voice-Over Unavailable',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadVoiceOverPath,
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Path: ${_currentVoiceOverPath ?? 'Not found'}',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_currentVoiceOverPath == null) {
      return _buildErrorWidget();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with controls
        Row(
          children: [
            const Icon(Icons.mic, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Voice-Over',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

        const SizedBox(height: 8),

        // Progress bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.purple,
            inactiveTrackColor: Colors.grey[600],
            thumbColor: Colors.purple,
            overlayColor: Colors.purple.withOpacity(0.2),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          ),
          child: Slider(
            value: _currentPosition.clamp(0.0, _totalDuration),
            min: 0.0,
            max: _totalDuration,
            onChanged: (value) {
              setState(() {
                _currentPosition = value;
              });
            },
            onChangeEnd: (value) {
              _seekTo(value);
            },
          ),
        ),

        // Duration text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              // Volume indicator
              if (_isPlaying)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up, color: Colors.white70, size: 12),
                      SizedBox(width: 2),
                      Text(
                        'Playing',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
