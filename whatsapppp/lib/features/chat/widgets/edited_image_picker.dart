import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/widgets/loader.dart';
import 'package:whatsapppp/features/multimedia_editing/repository/media_repository.dart';

class EditedImagePicker extends ConsumerWidget {
  final Function(String blobId) onImageSelected;

  EditedImagePicker({required this.onImageSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaRepo = ref.watch(mediaRepositoryProvider);
    final authUser = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Text(
            'Select Edited Image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: mediaRepo.getUserMediaFiles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No edited images found'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final mediaData = snapshot.data![index];
                    final blobId = mediaData['blobId'] as String;

                    return GestureDetector(
                      onTap: () => onImageSelected(blobId),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FutureBuilder<File?>(
                          future: mediaRepo.getMediaFileFromBlob(
                            blobId: blobId,
                            userId: authUser ?? '',
                          ),
                          builder: (context, fileSnapshot) {
                            if (fileSnapshot.hasData &&
                                fileSnapshot.data != null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  fileSnapshot.data!,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            return const Loader();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
