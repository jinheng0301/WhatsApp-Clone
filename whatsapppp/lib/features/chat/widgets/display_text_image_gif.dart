import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/common/widgets/blob_display_widget.dart';

class DisplayTextImageGif extends StatefulWidget {
  final String message;
  final MessageEnum type;

  const DisplayTextImageGif({
    required this.message,
    required this.type,
    Key? key,
  }) : super(key: key);

  @override
  State<DisplayTextImageGif> createState() => _DisplayTextImageGifState();
}

class _DisplayTextImageGifState extends State<DisplayTextImageGif> {
  bool isPlaying = false;
  AudioPlayer? audioPlayer;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.type == MessageEnum.audio) {
      _initializeAudioPlayer();
    }
  }

  void _initializeAudioPlayer() {
    audioPlayer = AudioPlayer();

    // Listen to audio duration changes
    audioPlayer!.onDurationChanged.listen((Duration d) {
      if (mounted) {
        setState(() {
          duration = d;
        });
      }
    });

    // Listen to audio position changes
    audioPlayer!.onPositionChanged.listen((Duration p) {
      if (mounted) {
        setState(() {
          position = p;
        });
      }
    });

    // Listen to player state changes
    audioPlayer!.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to completion
    audioPlayer!.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          position = Duration.zero;
        });
      }
    });
  }

  Future<void> _playPauseAudio() async {
    try {
      if (audioPlayer == null) return;

      if (isPlaying) {
        await audioPlayer!.pause();
      } else {
        // For blob audio, you need to get the URL from your blob storage
        // This is a simplified example - you'll need to implement getBlobUrl
        // await audioPlayer!.play(UrlSource(await getBlobUrl(widget.message)));

        // For now, assuming the message contains a file path or URL
        if (widget.message.startsWith('http')) {
          await audioPlayer!.play(UrlSource(widget.message));
        } else {
          // If it's a local file path
          await audioPlayer!.play(DeviceFileSource(widget.message));
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.type == MessageEnum.text
        ? Text(
            widget.message,
            style: const TextStyle(fontSize: 16),
          )
        : widget.type == MessageEnum.image
            ? BlobImage(fileId: widget.message)
            : widget.type == MessageEnum.video
                ? BlobVideo(fileId: widget.message)
                : widget.type == MessageEnum.audio
                    ? Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _playPauseAudio,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                size: 32,
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (duration != Duration.zero)
                                    LinearProgressIndicator(
                                      value: duration.inMilliseconds > 0
                                          ? position.inMilliseconds /
                                              duration.inMilliseconds
                                          : 0.0,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.green),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    duration != Duration.zero
                                        ? '${_formatDuration(position)} / ${_formatDuration(duration)}'
                                        : 'Audio Message',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: widget.message,
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      );
  }
}
