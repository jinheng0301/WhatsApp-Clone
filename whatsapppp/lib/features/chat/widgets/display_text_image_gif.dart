import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/features/chat/widgets/video_player_item.dart';

// ignore: must_be_immutable
class DisplayTextImageGif extends StatelessWidget {
  late final String message;
  late MessageEnum type;

  DisplayTextImageGif({
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    bool isPlaying = false;
    final AudioPlayer audioPlayer = AudioPlayer();

    return type == MessageEnum.text
        ? Text(
            message,
            style: const TextStyle(fontSize: 16),
          )
        : type == MessageEnum.audio
            ? StatefulBuilder(
                builder: (context, setState) {
                  return IconButton(
                    onPressed: () async {
                      if (isPlaying) {
                        audioPlayer.pause();
                        setState(() {
                          isPlaying = false;
                        });
                      } else {
                        await audioPlayer.play(UrlSource(message));
                        setState(() {
                          isPlaying = true;
                        });
                      }
                    },
                    icon:
                        Icon(isPlaying ? Icons.pause_circle : Icons.play_arrow),
                  );
                },
              )
            : type == MessageEnum.video
                ? VideoPlayerItem(
                    videoUrl: message,
                  )
                : type == MessageEnum.gif
                    ? CachedNetworkImage(
                        imageUrl: message,
                      )
                    : CachedNetworkImage(
                        imageUrl: message,
                      );
  }
}
