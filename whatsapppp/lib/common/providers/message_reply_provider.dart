import 'package:flutter_riverpod/legacy.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';

class MessageReply {
  final String message;
  final bool isMe;
  final MessageEnum messageEnum;

  MessageReply(
    this.message,
    this.isMe,
    this.messageEnum,
  );
}

final messageReplyProvider = StateProvider<MessageReply?>(
  (ref) => null,
);
