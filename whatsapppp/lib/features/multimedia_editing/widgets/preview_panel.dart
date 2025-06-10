import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PreviewPanel extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;

  const PreviewPanel({
    super.key,
    required this.mediaPath,
    required this.isVideo,
  });

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.file(File(widget.mediaPath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: widget.isVideo ? _buildVideoPreview() : _buildImagePreview(),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        IconButton(
          onPressed: _togglePlayPause,
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            size: 50,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Image.file(
        File(widget.mediaPath),
        fit: BoxFit.contain,
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }
}
