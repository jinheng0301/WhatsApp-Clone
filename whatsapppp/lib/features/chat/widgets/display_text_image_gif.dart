import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/common/widgets/blob_display_widget.dart';

class DisplayTextImageGif extends StatelessWidget {
  final String message;
  final MessageEnum type;

  const DisplayTextImageGif({
    required this.message,
    required this.type,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MessageEnum.text:
        return Text(
          message,
          style: const TextStyle(fontSize: 16),
        );
      case MessageEnum.image:
        return BlobImage(fileId: message);
      case MessageEnum.video:
        return BlobVideo(fileId: message);
      case MessageEnum.audio:
        return BlobAudio(fileId: message);
      case MessageEnum.gif:
        return CachedNetworkImage(
          imageUrl: message,
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
    }
  }
}
