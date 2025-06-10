import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:whatsapppp/features/multimedia_editing/screens/edit_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;

  const ConfirmationScreen({
    super.key,
    required this.mediaPath,
    required this.isVideo,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(File(widget.mediaPath))
        ..initialize().then((_) {
          setState(() => _isVideoInitialized = true);
        });
    }
  }

  @override
  void dispose() {
    if (widget.isVideo) _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Media'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: widget.isVideo
                  ? _buildVideoPreview()
                  : Image.file(File(widget.mediaPath)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _navigateToEditor,
                  child: const Icon(
                    Icons.done,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isVideoInitialized) {
      return const CircularProgressIndicator();
    }
    return AspectRatio(
      aspectRatio: _videoController.value.aspectRatio,
      child: VideoPlayer(_videoController),
    );
  }

  void _navigateToEditor() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(
          mediaPath: widget.mediaPath,
          isVideo: widget.isVideo,
        ),
      ),
    );
  }
}
