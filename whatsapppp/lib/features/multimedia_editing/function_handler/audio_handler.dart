import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/multimedia_editing/services/audio_service.dart';

class AudioHandler {
  String? _selectedMusicPath;
  String? _recordedVoiceOverPath;
  bool _isPreviewingAudio = false;

  // Getters for state
  String? get selectedMusicPath => _selectedMusicPath;
  String? get recordedVoiceOverPath => _recordedVoiceOverPath;
  bool get isPreviewingAudio => _isPreviewingAudio;

  // Background Music Functions
  Future<void> addBackgroundMusic(
    BuildContext context,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      final musicPath = await AudioService.pickAudioFile();
      if (musicPath != null) {
        _selectedMusicPath = musicPath;
        await _showMusicConfigDialog(
            context, musicPath, currentMediaPath, onMediaPathChanged);
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Error selecting music: $e');
      }
    }
  }

  Future<void> _showMusicConfigDialog(
    BuildContext context,
    String musicPath,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
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
        context,
        currentMediaPath,
        musicPath,
        result['audioVolume'],
        result['videoVolume'],
        result['loopAudio'],
        onMediaPathChanged,
      );
    }
  }

  Future<void> _applyBackgroundMusic(
    BuildContext context,
    String currentMediaPath,
    String musicPath,
    double audioVolume,
    double videoVolume,
    bool loopAudio,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      _showLoadingDialog(context, 'Adding background music...');

      final newPath = await AudioService.addBackgroundMusicToVideo(
        videoPath: currentMediaPath,
        audioPath: musicPath,
        audioVolume: audioVolume,
        videoVolume: videoVolume,
        loopAudio: loopAudio,
      );

      if (context.mounted) Navigator.pop(context);

      if (newPath != null) {
        onMediaPathChanged(newPath);
        if (context.mounted) {
          showSnackBar(context, 'Background music added successfully!');
        }
      } else {
        if (context.mounted) {
          showSnackBar(context, 'Failed to add background music');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error adding background music: $e');
      }
    }
  }

  Future<void> previewSelectedMusic(BuildContext context) async {
    if (_selectedMusicPath == null) {
      showSnackBar(context, 'Please select music first');
      return;
    }

    try {
      if (_isPreviewingAudio) {
        await AudioService.stopAudioPreview();
        _isPreviewingAudio = false;
      } else {
        await AudioService.previewAudio(_selectedMusicPath!);
        _isPreviewingAudio = true;

        // Auto-stop after 30 seconds preview
        Future.delayed(const Duration(seconds: 30), () {
          if (_isPreviewingAudio) {
            AudioService.stopAudioPreview();
            _isPreviewingAudio = false;
          }
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error previewing music: $e');
    }
  }

  // Original Audio Functions
  Future<void> muteOriginalAudio(
    BuildContext context,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      _showLoadingDialog(context, 'Muting original audio...');

      final newPath = await AudioService.muteOriginalAudio(currentMediaPath);

      if (context.mounted) Navigator.pop(context);

      if (newPath != null) {
        onMediaPathChanged(newPath);
        if (context.mounted) {
          showSnackBar(context, 'Original audio muted successfully!');
        }
      } else {
        if (context.mounted) {
          showSnackBar(context, 'Failed to mute original audio');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error muting audio: $e');
      }
    }
  }

  Future<void> showVolumeAdjustDialog(
    BuildContext context,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
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
      await _applyVolumeAdjustment(
          context, currentMediaPath, result, onMediaPathChanged);
    }
  }

  Future<void> _applyVolumeAdjustment(
    BuildContext context,
    String currentMediaPath,
    double volumeLevel,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      _showLoadingDialog(context, 'Adjusting volume...');

      final newPath = await AudioService.adjustOriginalAudioVolume(
        videoPath: currentMediaPath,
        volumeLevel: volumeLevel,
      );

      if (context.mounted) Navigator.pop(context);

      if (newPath != null) {
        onMediaPathChanged(newPath);
        if (context.mounted) {
          showSnackBar(context, 'Volume adjusted successfully!');
        }
      } else {
        if (context.mounted) {
          showSnackBar(context, 'Failed to adjust volume');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error adjusting volume: $e');
      }
    }
  }

  // Voice Over Functions
  Future<void> recordVoiceOver(
    BuildContext context,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      final recordedPath = await AudioService.recordVoiceOver(
        context: context,
        maxDurationSeconds: 300,
      );

      if (recordedPath != null) {
        _recordedVoiceOverPath = recordedPath;
        await _showVoiceOverConfigDialog(
          context,
          recordedPath,
          currentMediaPath,
          onMediaPathChanged,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Error recording voice over: $e');
      }
    }
  }

  Future<void> importVoiceOver(
    BuildContext context,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      final voiceOverPath = await AudioService.pickAudioFile();
      if (voiceOverPath != null) {
        _recordedVoiceOverPath = voiceOverPath;
        await _showVoiceOverConfigDialog(
            context, voiceOverPath, currentMediaPath, onMediaPathChanged);
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Error importing voice over: $e');
      }
    }
  }

  Future<void> _showVoiceOverConfigDialog(
    BuildContext context,
    String voiceOverPath,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
    double voiceVolume = 1.0;
    double originalVolume = 0.3;

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
        context,
        currentMediaPath,
        voiceOverPath,
        result['voiceVolume'],
        result['originalVolume'],
        onMediaPathChanged,
      );
    }
  }

  Future<void> _applyVoiceOver(
    BuildContext context,
    String currentMediaPath,
    String voiceOverPath,
    double voiceVolume,
    double originalVolume,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      _showLoadingDialog(context, 'Adding voice over...');

      final newPath = await AudioService.addVoiceOverToVideo(
        videoPath: currentMediaPath,
        voiceOverPath: voiceOverPath,
        voiceVolume: voiceVolume,
        originalVolume: originalVolume,
      );

      if (context.mounted) Navigator.pop(context);

      if (newPath != null) {
        onMediaPathChanged(newPath);
        if (context.mounted) {
          showSnackBar(context, 'Voice over added successfully!');
        }
      } else {
        if (context.mounted) {
          showSnackBar(context, 'Failed to add voice over');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error adding voice over: $e');
      }
    }
  }

  // Advanced Audio Functions
  Future<void> extractAudio(
      BuildContext context, String currentMediaPath) async {
    try {
      _showLoadingDialog(context, 'Extracting audio...');

      final audioPath =
          await AudioService.extractAudioFromVideo(currentMediaPath);

      if (context.mounted) Navigator.pop(context);

      if (audioPath != null) {
        if (context.mounted) {
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
        if (context.mounted) {
          showSnackBar(context, 'Failed to extract audio');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error extracting audio: $e');
      }
    }
  }

  Future<void> showAudioFadeDialog(
    BuildContext context,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
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
      await _applyAudioFade(context, currentMediaPath, result['fadeIn']!,
          result['fadeOut']!, onMediaPathChanged);
    }
  }

  Future<void> _applyAudioFade(
    BuildContext context,
    String currentMediaPath,
    double fadeInDuration,
    double fadeOutDuration,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      _showLoadingDialog(context, 'Applying audio fade...');

      final audioPath =
          await AudioService.extractAudioFromVideo(currentMediaPath);
      if (audioPath == null) throw Exception('Failed to extract audio');

      final fadedAudioPath = await AudioService.addAudioFade(
        audioPath: audioPath,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
      );

      if (fadedAudioPath == null) throw Exception('Failed to apply fade');

      final newVideoPath =
          await _replaceAudioInVideo(currentMediaPath, fadedAudioPath);

      if (context.mounted) Navigator.pop(context);

      if (newVideoPath != null) {
        onMediaPathChanged(newVideoPath);
        if (context.mounted) {
          showSnackBar(context, 'Audio fade applied successfully!');
        }
      } else {
        throw Exception('Failed to replace audio in video');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error applying audio fade: $e');
      }
    }
  }

  Future<void> showAudioTrimDialog(
    BuildContext context,
    String currentMediaPath,
    Function(String) onMediaPathChanged,
  ) async {
    double startTime = 0.0;
    double endTime = 30.0;

    final duration = await AudioService.getAudioDuration(currentMediaPath);
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
      await _applyAudioTrim(context, currentMediaPath, result['start']!,
          result['end']!, onMediaPathChanged);
    }
  }

  Future<void> _applyAudioTrim(
    BuildContext context,
    String currentMediaPath,
    double startTime,
    double endTime,
    Function(String) onMediaPathChanged,
  ) async {
    try {
      _showLoadingDialog(context, 'Trimming audio...');

      final trimmedPath = await AudioService.trimAudio(
        audioPath: currentMediaPath,
        startTime: Duration(seconds: startTime.round()),
        endTime: Duration(seconds: endTime.round()),
      );

      if (context.mounted) Navigator.pop(context);

      if (trimmedPath != null) {
        onMediaPathChanged(trimmedPath);
        if (context.mounted) {
          showSnackBar(context, 'Audio trimmed successfully!');
        }
      } else {
        if (context.mounted) {
          showSnackBar(context, 'Failed to trim audio');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Error trimming audio: $e');
      }
    }
  }

  // Helper Functions
  Future<String?> _replaceAudioInVideo(
      String videoPath, String audioPath) async {
    try {
      final outputPath = '${videoPath}_with_faded_audio.mp4';
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

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Cleanup method
  void dispose() {
    AudioService.stopAudioPreview();
  }
}
