import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerItem({
    required this.videoUrl,
    super.key,
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
    videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          isInitialized = true;
        });
        videoPlayerController.setVolume(1.0);
      });
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
