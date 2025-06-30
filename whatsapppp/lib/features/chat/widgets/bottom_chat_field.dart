import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/common/providers/message_reply_provider.dart';
import 'package:whatsapppp/common/utils/color.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/chat/controller/chat_controller.dart';
import 'package:whatsapppp/features/chat/widgets/edited_image_picker.dart';
import 'package:whatsapppp/features/chat/widgets/message_reply_preview.dart';
import 'package:whatsapppp/features/multimedia_editing/repository/media_repository.dart';

class BottomChatField extends ConsumerStatefulWidget {
  late final String receiverUserId;
  late final bool isGroupChat;

  BottomChatField({
    required this.isGroupChat,
    required this.receiverUserId,
  });

  @override
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends ConsumerState<BottomChatField> {
  final TextEditingController messageController = TextEditingController();
  final authUser = FirebaseAuth.instance.currentUser?.uid;
  FlutterSoundRecorder? soundRecorder;
  bool isShowSendButton = false;
  bool isRecorderInit = false;
  bool isShowEmojiContainer = false;
  bool isRecording = false;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    soundRecorder = FlutterSoundRecorder();
    _initializeAudio();
  }

  // Initialize audio recording
  void _initializeAudio() async {
    try {
      openAudio();
      print('Audio recorder initialized successfully');
    } catch (e) {
      print('Error initializing audio recorder: $e');
    }
  }

  void openAudio() async {
    try {
      // Check if the microphone permission is granted
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('Mic permission not allowed!');
        if (mounted) {
          showSnackBar(
              context, 'Microphone permission is required for voice messages');
        }
        return;
      }
      await soundRecorder!.openRecorder();
      setState(() {
        isRecorderInit = true;
      });
    } catch (e) {
      print('Error opening audio recorder: $e');
      if (mounted) {
        showSnackBar(context, 'Error opening audio recorder: $e');
      }
    }
  }

  Future<void> _handleAudioRecording() async {
    try {
      if (!isRecorderInit) {
        print('Recorder not initialized, attempting to initialize...');
        _initializeAudio();
        if (!isRecorderInit) {
          showSnackBar(context, 'Voice recording not available');
          return;
        }
      }

      if (isRecording) {
        // Stop recording
        print('Stopping audio recording...');
        String? path = await soundRecorder!.stopRecorder();

        if (path != null && File(path).existsSync()) {
          print('Audio recorded successfully at: $path');
          // Send the recorded audio file
          sendFileMessage(File(path), MessageEnum.audio);
          showSnackBar(context, 'Voice message sent!');
        } else {
          print('Recording failed - no file created');
          showSnackBar(context, 'Recording failed');
        }

        setState(() {
          isRecording = false;
        });
      } else {
        // Start recording
        print('Starting audio recording...');
        var tempDir = await getTemporaryDirectory();
        var path =
            '${tempDir.path}/flutter_sound_${DateTime.now().millisecondsSinceEpoch}.aac';

        await soundRecorder!.startRecorder(
          toFile: path,
          codec: Codec.aacADTS, // Specify codec for better compatibility
        );

        setState(() {
          isRecording = true;
        });

        print('Recording started, saving to: $path');
        showSnackBar(context, 'Recording voice message...');
      }
    } catch (e) {
      print('Error in audio recording: $e');
      setState(() {
        isRecording = false;
      });
      showSnackBar(context, 'Recording error: $e');
    }
  }

  void sendTextMessage() async {
    if (isShowSendButton) {
      ref.read(chatControllerProvider).sendTextMessage(
            context,
            messageController.text.trim(),
            widget.receiverUserId,
            widget.isGroupChat,
          );
      setState(() {
        messageController.text = '';
      });
    } else {
      await _handleAudioRecording();
    }
  }

  // Function to send file messages
  // This function manages a file and a message type (image, video, audio) and sends the file
  void sendFileMessage(
    File file,
    MessageEnum messageEnum,
  ) {
    ref.read(chatControllerProvider).sendFileMessage(
          context,
          file,
          widget.receiverUserId,
          messageEnum,
          widget.isGroupChat,
        );
  }

  // Function to select an image from the gallery
  // This function uses the pickImageFromGallery function to select an image
  void selectImage() async {
    File? image = await pickImageFromGallery(context);
    if (image != null) {
      sendFileMessage(image, MessageEnum.image);
    }
  }

  void selectEditedImage() async {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return EditedImagePicker(
            onImageSelected: (String blobId) async {
              Navigator.pop(context);
              // Get the edited image file from blob storage
              final mediaRepo = ref.read(mediaRepositoryProvider);
              final userId = authUser ?? '';

              File? editedImageFile = await mediaRepo.getMediaFileFromBlob(
                blobId: blobId,
                userId: userId,
              );

              if (editedImageFile != null) {
                sendFileMessage(editedImageFile, MessageEnum.image);
              } else {
                showSnackBar(context, 'Failed to load edited image');
              }
            },
          );
        });
  }

  void selectVideo() async {
    File? video = await pickVideoFromGallery(context);
    if (video != null) {
      sendFileMessage(video, MessageEnum.video);
    }
  }

  void selectGIF() async {
    final gif = await pickGIF(context);
    if (gif != null) {
      ref.read(chatControllerProvider).sendGIFMessage(
            context,
            gif.url,
            widget.receiverUserId,
            widget.isGroupChat,
          );
    }
  }

  void hideEmojiContainer() {
    setState(() {
      isShowEmojiContainer = false;
    });
  }

  void showEmojiContainer() {
    setState(() {
      isShowEmojiContainer = true;
    });
  }

  void showKeyboard() => focusNode.requestFocus();
  void hideKeyboard() => focusNode.unfocus();

  void toggleEmojiKeyboardContainer() {
    if (isShowEmojiContainer) {
      // If the emoji container is already shown, hide it and show the keyboard
      // This is to prevent the keyboard from showing when the emoji container is already open
      showKeyboard();
      hideEmojiContainer();
    } else {
      // If the emoji container is not shown, hide the keyboard and show the emoji container
      // This is to prevent the keyboard from showing when the emoji container is already open
      hideKeyboard();
      showEmojiContainer();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    messageController.dispose();
    // Properly close the recorder
    if (isRecorderInit && soundRecorder != null) {
      soundRecorder!.closeRecorder();
    }
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageReply = ref.watch(messageReplyProvider);
    final isShowMessageReply = (messageReply != null);

    return Column(
      children: [
        isShowMessageReply ? const MessageReplyPreview() : const SizedBox(),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                focusNode: focusNode,
                controller: messageController,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      isShowSendButton = true;
                    });
                  } else {
                    setState(() {
                      isShowSendButton = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: mobileChatBoxColor,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: toggleEmojiKeyboardContainer,
                            icon: const Icon(
                              Icons.emoji_emotions,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            onPressed: selectGIF,
                            icon: const Icon(
                              Icons.gif,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  suffixIcon: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: selectImage,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: selectEditedImage,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: selectVideo,
                          icon: const Icon(
                            Icons.attach_file,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  hintText: 'Type a message!',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ),

            // recording
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
                right: 2,
                left: 2,
              ),
              child: CircleAvatar(
                backgroundColor:
                    isRecording ? Colors.red : const Color(0xFF128C7E),
                radius: 25,
                child: InkWell(
                  onTap: sendTextMessage,
                  child: Icon(
                    isShowSendButton
                        ? Icons.send
                        : isRecording
                            ? Icons.close
                            : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        isShowEmojiContainer
            ? SizedBox(
                height: 310,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      // Add the selected emoji to the message
                      messageController.text =
                          messageController.text + emoji.emoji;
                    });
                    if (!isShowSendButton) {
                      setState(() {
                        isShowSendButton = true;
                      });
                    }
                  },
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
