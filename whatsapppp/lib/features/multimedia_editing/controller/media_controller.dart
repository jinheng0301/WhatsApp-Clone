import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/multimedia_editing/repository/media_repository.dart';

// State providers for media editing
final isEditingProvider = StateProvider<bool>((ref) => false);
final currentMediaFileProvider = StateProvider<File?>((ref) => null);
final editingProgressProvider = StateProvider<double>((ref) => 0.0);
final selectedFilterProvider = StateProvider<String?>((ref) => null);

// Controller provider
final mediaControllerProvider = Provider((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  return MediaController(
    mediaRepository: mediaRepository,
    ref: ref,
  );
});

// User editing history provider
final userEditingHistoryProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  return mediaRepository.getUserEditingHistory();
});

class MediaController {
  final MediaRepository mediaRepository;
  final Ref ref;

  MediaController({
    required this.mediaRepository,
    required this.ref,
  });

  // Image editing methods
  Future<File?> cropImage({
    required File imageFile,
    required Rect cropRect,
    required Size originalSize,
    required BuildContext context,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;

      final croppedFile = await mediaRepository.cropImage(
        imageFile: imageFile,
        cropRect: cropRect,
        originalSize: originalSize,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;
      ref.read(currentMediaFileProvider.notifier).state = croppedFile;

      showSnackBar(context, 'Image cropped successfully');
      return croppedFile;
    } catch (e) {
      showSnackBar(context, 'Failed to crop image: ${e.toString()}');
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  Future<File?> applyImageFilter({
    required File imageFile,
    required String filterType,
    required BuildContext context,
    double intensity = 1.0,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;
      ref.read(selectedFilterProvider.notifier).state = filterType;

      final filteredFile = await mediaRepository.applyImageFilter(
        imageFile: imageFile,
        filterType: filterType,
        intensity: intensity,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;
      ref.read(currentMediaFileProvider.notifier).state = filteredFile;

      showSnackBar(context, 'Filter applied successfully');
      return filteredFile;
    } catch (e) {
      showSnackBar(context, 'Failed to apply filter: ${e.toString()}');
      ref.read(selectedFilterProvider.notifier).state = null;
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  Future<File?> addTextToImage({
    required File imageFile,
    required String text,
    required Offset position,
    required double fontSize,
    required Color textColor,
    required String fontFamily,
    required BuildContext context,
    bool isBold = false,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;

      final textFile = await mediaRepository.addTextToImage(
        imageFile: imageFile,
        text: text,
        position: position,
        fontSize: fontSize,
        textColor: textColor,
        fontFamily: fontFamily,
        isBold: isBold,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;
      ref.read(currentMediaFileProvider.notifier).state = textFile;

      showSnackBar(context, 'Text added successfully');
      return textFile;
    } catch (e) {
      showSnackBar(context, 'Failed to add text: ${e.toString()}');
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  // Video editing methods
  Future<File?> trimVideo({
    required File videoFile,
    required Duration startTime,
    required Duration endTime,
    required BuildContext context,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;

      final trimmedFile = await mediaRepository.trimVideo(
        videoFile: videoFile,
        startTime: startTime,
        endTime: endTime,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;
      ref.read(currentMediaFileProvider.notifier).state = trimmedFile;

      showSnackBar(context, 'Video trimmed successfully');
      return trimmedFile;
    } catch (e) {
      showSnackBar(context, 'Failed to trim video: ${e.toString()}');
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  Future<File?> addAudioToVideo({
    required File videoFile,
    required File audioFile,
    required BuildContext context,
    double volume = 1.0,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;

      final outputFile = await mediaRepository.addAudioToVideo(
        videoFile: videoFile,
        audioFile: audioFile,
        volume: volume,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;
      ref.read(currentMediaFileProvider.notifier).state = outputFile;

      showSnackBar(context, 'Audio added successfully');
      return outputFile;
    } catch (e) {
      showSnackBar(context, 'Failed to add audio: ${e.toString()}');
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  Future<File?> applyVideoFilter({
    required File videoFile,
    required String filterType,
    required BuildContext context,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;
      ref.read(selectedFilterProvider.notifier).state = filterType;

      final filteredFile = await mediaRepository.applyVideoFilter(
        videoFile: videoFile,
        filterType: filterType,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;
      ref.read(currentMediaFileProvider.notifier).state = filteredFile;

      showSnackBar(context, 'Video filter applied successfully');
      return filteredFile;
    } catch (e) {
      showSnackBar(context, 'Failed to apply video filter: ${e.toString()}');
      ref.read(selectedFilterProvider.notifier).state = null;
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  // Save and sharing methods
  Future<String?> saveEditedMediaToCloud({
    required File mediaFile,
    required String mediaType,
    required BuildContext context,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;

      final downloadUrl = await mediaRepository.saveEditedMedia(
        mediaFile: mediaFile,
        mediaType: mediaType,
        ref: ref,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;

      showSnackBar(context, 'Media saved to cloud successfully');
      return downloadUrl;
    } catch (e) {
      showSnackBar(context, 'Failed to save media: ${e.toString()}');
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  Future<void> saveEditingSession({
    required String sessionId,
    required String mediaType,
    required String originalMediaUrl,
    required Map<String, dynamic> editingData,
    required BuildContext context,
  }) async {
    try {
      await mediaRepository.saveEditingSession(
        sessionId: sessionId,
        mediaType: mediaType,
        originalMediaUrl: originalMediaUrl,
        editingData: editingData,
      );

      showSnackBar(context, 'Editing session saved');
    } catch (e) {
      showSnackBar(context, 'Failed to save session: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> loadEditingSession({
    required String sessionId,
    required BuildContext context,
  }) async {
    try {
      final sessionData = await mediaRepository.loadEditingSession(sessionId);

      if (sessionData != null) {
        showSnackBar(context, 'Editing session loaded');
      }

      return sessionData;
    } catch (e) {
      showSnackBar(context, 'Failed to load session: ${e.toString()}');
      return null;
    }
  }

  // Utility methods
  void resetEditingState() {
    ref.read(isEditingProvider.notifier).state = false;
    ref.read(currentMediaFileProvider.notifier).state = null;
    ref.read(editingProgressProvider.notifier).state = 0.0;
    ref.read(selectedFilterProvider.notifier).state = null;
  }

  void updateEditingProgress(double progress) {
    ref.read(editingProgressProvider.notifier).state = progress;
  }

  void setCurrentMediaFile(File? file) {
    ref.read(currentMediaFileProvider.notifier).state = file;
  }

  // Get editing history stream
  Stream<List<Map<String, dynamic>>> getEditingHistory() {
    return mediaRepository.getUserEditingHistory();
  }
}
