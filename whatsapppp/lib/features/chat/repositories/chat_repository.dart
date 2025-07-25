import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapppp/common/enums/message_enums.dart';
import 'package:whatsapppp/common/providers/message_reply_provider.dart';
import 'package:whatsapppp/common/repositories/common_blob_storage_repository.dart';
import 'package:whatsapppp/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/models/chat_contact.dart';
import 'package:whatsapppp/models/group.dart';
import 'package:whatsapppp/models/message.dart';
import 'package:whatsapppp/models/user_model.dart';

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChatRepository({
    required this.firestore,
    required this.auth,
  });

  // SEND TEXT MESSAGE
  // This method is used to send text messages
  void sendTextMessage({
    required BuildContext context,
    required String text,
    required String recieverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      print('ChatRepository: Starting sendTextMessage');
      print('Sender: ${senderUser.name} (${senderUser.uid})');
      print('Receiver ID: $recieverUserId');
      print('Text: $text');
      print('Is Group Chat: $isGroupChat');

      // Check if user is authenticated
      if (auth.currentUser == null) {
        print('ChatRepository: No authenticated user');
        showSnackBar(context, 'User not authenticated');
        return;
      }

      print('ChatRepository: Current user UID: ${auth.currentUser!.uid}');

      // For group chats, verify the group exists before proceeding
      if (isGroupChat) {
        print('ChatRepository: Verifying group existence');
        var groupDoc =
            await firestore.collection('groups').doc(recieverUserId).get();
        if (!groupDoc.exists) {
          print('ChatRepository: Group does not exist, cannot send message');
          showSnackBar(context,
              'Group does not exist or you may not have permission to access it');
          return;
        }
        print('ChatRepository: Group exists, proceeding with message send');
      }

      var timeSent = DateTime.now();
      UserModel? recieverUserData;

      if (!isGroupChat) {
        print('ChatRepository: Fetching receiver user data');
        try {
          var userDataMap =
              await firestore.collection('users').doc(recieverUserId).get();

          if (!userDataMap.exists) {
            print('ChatRepository: Receiver user document does not exist');
            showSnackBar(context, 'Receiver user not found');
            return;
          }

          var userData = userDataMap.data();
          if (userData == null) {
            print('ChatRepository: Receiver user data is null');
            showSnackBar(context, 'Receiver user data is invalid');
            return;
          }

          recieverUserData = UserModel.fromMap(userData);
          print(
              'ChatRepository: Receiver user data loaded: ${recieverUserData.name}');
        } catch (e) {
          print('ChatRepository: Error fetching receiver user data: $e');
          showSnackBar(context, 'Error fetching receiver data: $e');
          return;
        }
      }

      var messageId = const Uuid().v1();
      print('ChatRepository: Generated message ID: $messageId');

      // Save data to contacts subcollection
      print('ChatRepository: Saving data to contacts subcollection');
      try {
        await _saveDataToContactsSubcollection(
          senderUser,
          recieverUserData,
          text,
          timeSent,
          recieverUserId,
          isGroupChat,
        );
      } catch (e) {
        print('ChatRepository: Error saving to contacts subcollection: $e');
        showSnackBar(context, 'Error updating contacts: ${e.toString()}');
        return;
      }

      // Save message to message subcollection
      print('ChatRepository: Saving message to message subcollection');
      try {
        await _saveMessageToMessageSubcollection(
          recieverUserId: recieverUserId,
          text: text,
          timeSent: timeSent,
          messageType: MessageEnum.text,
          messageId: messageId,
          username: senderUser.name,
          messageReply: messageReply,
          recieverUserName: recieverUserData?.name,
          senderUsername: senderUser.name,
          isGroupChat: isGroupChat,
        );
      } catch (e) {
        print('ChatRepository: Error saving message: $e');
        showSnackBar(context, 'Error saving message: ${e.toString()}');
        return;
      }

      print('ChatRepository: Message sent successfully');
      showSnackBar(context, 'Message sent successfully');
    } catch (e) {
      print('ChatRepository: Error in sendTextMessage: $e');
      showSnackBar(context, 'Failed to send message: ${e.toString()}');
    }
  }

  // Enhanced _saveDataToContactsSubcollection with better error handling
  // This method is used to save the message data to the contacts subcollection
  Future<void> _saveDataToContactsSubcollection(
    UserModel senderUserData,
    UserModel? recieverUserData,
    String text,
    DateTime timeSent,
    String recieverUserId,
    bool isGroupChat,
  ) async {
    try {
      print('_saveDataToContactsSubcollection: Starting');

      if (isGroupChat) {
        print('_saveDataToContactsSubcollection: Updating group chat');

        // First check if the group document exists
        var groupDoc =
            await firestore.collection('groups').doc(recieverUserId).get();

        if (!groupDoc.exists) {
          print(
              '_saveDataToContactsSubcollection: Group document does not exist');
          throw Exception(
              'Group document with ID $recieverUserId does not exist');
        }

        // Update the existing group document
        await firestore.collection('groups').doc(recieverUserId).update({
          'lastMessage': text,
          'timeSent': DateTime.now().millisecondsSinceEpoch,
        });

        print('_saveDataToContactsSubcollection: Group updated successfully');
      } else {
        print('_saveDataToContactsSubcollection: Updating individual chat');

        if (recieverUserData == null) {
          print('_saveDataToContactsSubcollection: Receiver user data is null');
          throw Exception(
              'Cannot save contact data: Receiver user data is missing');
        }

        // Create receiver's chat contact
        var receiverChatContact = ChatContact(
          name: senderUserData.name,
          profilePic: senderUserData.profilePic,
          contactId: senderUserData.uid,
          timeSent: timeSent,
          lastMessage: text,
        );

        print('_saveDataToContactsSubcollection: Saving to receiver chat list');
        await firestore
            .collection('users')
            .doc(recieverUserId)
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .set(receiverChatContact.toMap());

        // Create sender's chat contact
        var senderChatContact = ChatContact(
          name: recieverUserData.name,
          profilePic: recieverUserData.profilePic,
          contactId: recieverUserData.uid,
          timeSent: timeSent,
          lastMessage: text,
        );

        print('_saveDataToContactsSubcollection: Saving to sender chat list');
        await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(recieverUserId)
            .set(senderChatContact.toMap());
      }

      print('_saveDataToContactsSubcollection: Completed successfully');
    } catch (e) {
      print('_saveDataToContactsSubcollection: Error: $e');
      throw e; // Re-throw to be caught by the calling function
    }
  }

  // Enhanced _saveMessageToMessageSubcollection with better error handling
  // This method is used to save the message data to the message subcollection
  Future<void> _saveMessageToMessageSubcollection({
    required String recieverUserId,
    required String text,
    required DateTime timeSent,
    required String messageId,
    required String username,
    required MessageEnum messageType,
    required MessageReply? messageReply,
    required String senderUsername,
    required String? recieverUserName,
    required bool isGroupChat,
  }) async {
    try {
      print('_saveMessageToMessageSubcollection: Starting');

      final message = Message(
        senderId: auth.currentUser!.uid,
        recieverid: recieverUserId,
        text: text,
        type: messageType,
        timeSent: timeSent,
        messageId: messageId,
        isSeen: false,
        repliedMessage: messageReply == null ? '' : messageReply.message,
        repliedTo: messageReply == null
            ? ''
            : messageReply.isMe
                ? senderUsername
                : recieverUserName ?? '',
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageEnum,
      );

      print('_saveMessageToMessageSubcollection: Message object created');

      if (isGroupChat) {
        print('_saveMessageToMessageSubcollection: Saving group message');
        await firestore
            .collection('groups')
            .doc(recieverUserId)
            .collection('chats')
            .doc(messageId)
            .set(message.toMap());
      } else {
        print('_saveMessageToMessageSubcollection: Saving individual messages');

        // Save to sender's message collection
        print(
            '_saveMessageToMessageSubcollection: Saving to sender collection');
        await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .collection('chats')
            .doc(recieverUserId)
            .collection('messages')
            .doc(messageId)
            .set(message.toMap());

        // Save to receiver's message collection
        print(
            '_saveMessageToMessageSubcollection: Saving to receiver collection');
        await firestore
            .collection('users')
            .doc(recieverUserId)
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .collection('messages')
            .doc(messageId)
            .set(message.toMap());
      }

      print('_saveMessageToMessageSubcollection: Completed successfully');
    } catch (e) {
      print('_saveMessageToMessageSubcollection: Error: $e');
      throw e; // Re-throw to be caught by the calling function
    }
  }

  // GET CHAT CONTACTS
  Stream<List<ChatContact>> getChatContacts() {
    print(
        'getChatContacts: Starting stream for user: ${auth.currentUser?.uid}');
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      print('getChatContacts: Received ${event.docs.length} chat documents');
      List<ChatContact> contacts = [];
      for (var document in event.docs) {
        var chatContact = ChatContact.fromMap(document.data());
        var userData = await firestore
            .collection('users')
            .doc(chatContact.contactId)
            .get();
        var user = UserModel.fromMap(userData.data()!);

        contacts.add(
          ChatContact(
            name: user.name,
            profilePic: user.profilePic,
            contactId: chatContact.contactId,
            timeSent: chatContact.timeSent,
            lastMessage: chatContact.lastMessage,
          ),
        );
      }
      print('getChatContacts: Returning ${contacts.length} contacts');
      return contacts;
    });
  }

  // GET CHAT STREAM
  Stream<List<Message>> getChatStream(String recieverUserId) {
    print(
        'getChatStream: Starting stream for conversation with: $recieverUserId');
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(recieverUserId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      print('getChatStream: Received ${event.docs.length} messages');
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  // GET CHAT GROUPS
  Stream<List<GroupChat>> getChatGroups() {
    print('getChatGroups: Starting stream for user: ${auth.currentUser?.uid}');

    // Query only groups where the current user is a member
    // This avoids the permission denied error
    return firestore
        .collection('groups')
        .where('membersUid', arrayContains: auth.currentUser!.uid)
        .snapshots()
        .map((event) {
      print('getChatGroups: Received ${event.docs.length} group documents');
      List<GroupChat> groups = [];

      for (var document in event.docs) {
        try {
          var group = GroupChat.fromMap(document.data());
          groups.add(group);
          print('getChatGroups: Added group: ${group.name}');
        } catch (e) {
          print(
              'getChatGroups: Error parsing group document ${document.id}: $e');
        }
      }

      print('getChatGroups: Returning ${groups.length} groups');
      return groups;
    }).handleError((error) {
      print('getChatGroups: Stream error: $error');
      return <GroupChat>[];
    });
  }

  // GET GROUP CHAT STREAM
  Stream<List<Message>> getGroupChatStream(String groudId) {
    return firestore
        .collection('groups')
        .doc(groudId)
        .collection('chats')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  // CREATE GROUP
  Future<void> createGroup(
    BuildContext context,
    String name,
    File? profilePic,
    List<String> selectedMemberUids,
    Ref ref,
  ) async {
    try {
      String groupId = const Uuid().v1();

      // Add current user to the group members
      List<String> allMemberUids = [
        auth.currentUser!.uid,
        ...selectedMemberUids
      ];

      String groupPicUrl = '';

      if (profilePic != null) {
        groupPicUrl = await ref
            .read(CommonFirebaseStorageRepositoryProvider)
            .storeFileToFirebase(
              'group/$groupId',
              profilePic,
            );
      }

      // Create a new group document
      GroupChat group = GroupChat(
        senderId: auth.currentUser!.uid,
        name: name,
        groupId: groupId,
        lastMessage: '',
        groupPic: groupPicUrl,
        membersUid: allMemberUids,
        timeSent: DateTime.now(),
      );

      await firestore.collection('groups').doc(groupId).set(group.toMap());

      showSnackBar(context, 'Group created successfully!');
    } catch (e) {
      showSnackBar(context, 'Error creating group: ${e.toString()}');
    }
  }

  // SEND FILE MESSAGE
  // This method is used to send files like images, videos, and audio
  // FIXED: Modified sendFileMessage to save chat files to media subcollection
  void sendFileMessage({
    required BuildContext context,
    required File file,
    required String recieverUserId,
    required UserModel senderUserData,
    required Ref ref,
    required MessageEnum messageEnum,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      print('ChatRepository: Starting sendFileMessage');
      print('Sender: ${senderUserData.name} (${senderUserData.uid})');
      print('Receiver ID: $recieverUserId');
      print('Message Type: ${messageEnum.name}');
      print('Is Group Chat: $isGroupChat');

      var timeSent = DateTime.now();
      var messageId = const Uuid().v1();

      String fileId = '';
      try {
        // FIXED: Store the file as blob using a path that indicates it's chat media
        final chatMediaPath = isGroupChat
            ? 'chat/${messageEnum.type}/groups/$recieverUserId/$messageId'
            : 'chat/${messageEnum.type}/${senderUserData.uid}/$recieverUserId/$messageId';

        fileId =
            await ref.read(commonBlobStorageRepositoryProvider).storeFileAsBlob(
                  chatMediaPath,
                  file,
                  context,
                );
        print('ChatRepository: File stored with ID: $fileId');

        // FIXED: Save chat media metadata to media subcollection
        await _saveChatMediaToSubcollection(
          fileId: fileId,
          senderUserId: senderUserData.uid,
          recieverUserId: recieverUserId,
          messageType: messageEnum,
          filePath: chatMediaPath,
          isGroupChat: isGroupChat,
          timeSent: timeSent,
        );
      } catch (e) {
        print('ChatRepository: Error storing file: $e');
        showSnackBar(context, 'Error uploading file: ${e.toString()}');
        return;
      }

      UserModel? recieverUserData;
      if (!isGroupChat) {
        try {
          var userDataMap =
              await firestore.collection('users').doc(recieverUserId).get();

          if (!userDataMap.exists || userDataMap.data() == null) {
            print('ChatRepository: Receiver user data not found');
            showSnackBar(context, 'Receiver user not found');
            return;
          }

          recieverUserData = UserModel.fromMap(userDataMap.data()!);
          print(
              'ChatRepository: Receiver data loaded: ${recieverUserData.name}');
        } catch (e) {
          print('ChatRepository: Error fetching receiver data: $e');
          showSnackBar(
              context, 'Error fetching receiver data: ${e.toString()}');
          return;
        }
      }

      String contactMsg;
      switch (messageEnum) {
        case MessageEnum.image:
          contactMsg = '📷 Photo';
          break;
        case MessageEnum.video:
          contactMsg = '📸 Video';
          break;
        case MessageEnum.audio:
          contactMsg = '🎵 Audio';
          break;
        case MessageEnum.gif:
          contactMsg = 'GIF';
          break;
        default:
          contactMsg = 'File';
      }

      try {
        print('ChatRepository: Updating contacts subcollection');
        await _saveDataToContactsSubcollection(
          senderUserData,
          recieverUserData,
          contactMsg,
          timeSent,
          recieverUserId,
          isGroupChat,
        );
      } catch (e) {
        print('ChatRepository: Error updating contacts: $e');
        showSnackBar(context, 'Error updating contacts: ${e.toString()}');
        return;
      }

      try {
        print('ChatRepository: Saving message');
        await _saveMessageToMessageSubcollection(
          recieverUserId: recieverUserId,
          text: fileId, // Store the file ID
          timeSent: timeSent,
          messageId: messageId,
          username: senderUserData.name,
          messageType: messageEnum,
          messageReply: messageReply,
          recieverUserName: recieverUserData?.name,
          senderUsername: senderUserData.name,
          isGroupChat: isGroupChat,
        );
      } catch (e) {
        print('ChatRepository: Error saving message: $e');
        showSnackBar(context, 'Error saving message: ${e.toString()}');
        return;
      }

      print('ChatRepository: File message sent successfully');
    } catch (e) {
      print('ChatRepository: Error in sendFileMessage: $e');
      showSnackBar(context, 'Failed to send file: ${e.toString()}');
    }
  }

  // NEW METHOD: Save chat media metadata to media subcollection
  Future<void> _saveChatMediaToSubcollection({
    required String fileId,
    required String senderUserId,
    required String recieverUserId,
    required MessageEnum messageType,
    required String filePath,
    required bool isGroupChat,
    required DateTime timeSent,
  }) async {
    try {
      print('ChatRepository: Saving chat media to subcollection');

      // FIXED: Get the actual blob data from temporary storage
      final tempMediaDoc =
          await firestore.collection('temp_chat_media').doc(fileId).get();

      if (!tempMediaDoc.exists || tempMediaDoc.data() == null) {
        throw Exception('Temporary media data not found for fileId: $fileId');
      }

      final tempData = tempMediaDoc.data()!;
      print('ChatRepository: Retrieved temporary media data');

      // FIXED: Prepare complete media data with actual blob content
      final mediaData = {
        'fileId': fileId,
        'senderUserId': senderUserId,
        'recieverUserId': recieverUserId,
        'messageType': messageType.name,
        'filePath': filePath,
        'isGroupChat': isGroupChat,
        'timeSent': timeSent,
        'storageType': 'chat_media',
        'createdAt': FieldValue.serverTimestamp(),
        // IMPORTANT: Include the actual base64 data
        'data': tempData['data'], // This contains the base64 image data
        'contentType': tempData['contentType'],
        'size': tempData['size'],
        'originalSize': tempData['originalSize'],
      };

      // Save to sender's media subcollection
      await firestore
          .collection('users')
          .doc(senderUserId)
          .collection('media')
          .doc(fileId)
          .set(mediaData);

      print('ChatRepository: Saved to sender media subcollection');

      // Save to receiver's media subcollection (if not group chat)
      if (!isGroupChat) {
        await firestore
            .collection('users')
            .doc(recieverUserId)
            .collection('media')
            .doc(fileId)
            .set(mediaData);

        print('ChatRepository: Saved to receiver media subcollection');
      } else {
        // For group chats, save to all group members' media subcollections
        try {
          final groupDoc =
              await firestore.collection('groups').doc(recieverUserId).get();

          if (groupDoc.exists && groupDoc.data() != null) {
            final groupData = groupDoc.data()!;
            final memberUids = List<String>.from(groupData['membersUid'] ?? []);

            // Update media data for group chat
            final groupMediaData = {
              ...mediaData,
              'isGroupChat': true,
              'groupId': recieverUserId,
            };

            for (final memberUid in memberUids) {
              await firestore
                  .collection('users')
                  .doc(memberUid)
                  .collection('media')
                  .doc(fileId)
                  .set(groupMediaData);
            }

            print(
                'ChatRepository: Saved to all group members media subcollections');
          }
        } catch (e) {
          print('ChatRepository: Error saving to group members: $e');
        }
      }

      // FIXED: Clean up temporary storage
      await firestore.collection('temp_chat_media').doc(fileId).delete();

      print('ChatRepository: Cleaned up temporary storage');
      print(
          'ChatRepository: Chat media metadata saved to subcollections successfully');
    } catch (e) {
      print('ChatRepository: Error saving chat media metadata: $e');
      throw e;
    }
  }

  void sendGIFMessage({
    required BuildContext context,
    required String gifUrl,
    required String recieverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSent = DateTime.now();
      UserModel? recieverUserData;

      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(recieverUserId).get();
        recieverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();

      // For GIFs from URLs, we need to download and store them as blobs
      // This is a bit simplified for example purposes
      // In a real app, you might want to use a package like http to download the GIF

      // Here we'll just store the GIF URL directly for simplicity
      // In a real implementation, you would:
      // 1. Download the GIF using http package
      // 2. Store it as a blob using CommonBlobStorageRepository

      _saveDataToContactsSubcollection(
        senderUser,
        recieverUserData,
        'GIF',
        timeSent,
        recieverUserId,
        isGroupChat,
      );

      _saveMessageToMessageSubcollection(
        recieverUserId: recieverUserId,
        text: gifUrl, // In a real implementation, this would be the blob ID
        timeSent: timeSent,
        messageType: MessageEnum.gif,
        messageId: messageId,
        username: senderUser.name,
        messageReply: messageReply,
        recieverUserName: recieverUserData?.name,
        senderUsername: senderUser.name,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void setChatMessageSeen(
    BuildContext context,
    String recieverUserId,
    String messageId,
  ) async {
    try {
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(recieverUserId)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});

      await firestore
          .collection('users')
          .doc(recieverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
}
