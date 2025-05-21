import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final Uint8List? blobData;

  VideoPlayerItem({
    required this.videoUrl,
    this.blobData,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController videoPlayerController;
  bool isPlay = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    if (widget.videoUrl.startsWith('memory://') && widget.blobData != null) {
      // Use memory data source
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse('data:video/mp4;base64,${_bytesToBase64(widget.blobData!)}'),
      );
    } else {
      // Use regular URL
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
    }

    await videoPlayerController.initialize();

    if (mounted) {
      setState(() {
        isInitialized = true;
      });
      videoPlayerController.setVolume(1.0);
    }
  }

  String _bytesToBase64(Uint8List bytes) {
    return Uri.encodeFull(String.fromCharCodes(bytes));
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isInitialized
        ? AspectRatio(
            aspectRatio: videoPlayerController.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(videoPlayerController),
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(
                      isPlay ? Icons.pause_circle : Icons.play_circle,
                      size: 48,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPlay) {
                          videoPlayerController.pause();
                        } else {
                          videoPlayerController.play();
                        }
                        isPlay = !isPlay;
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
