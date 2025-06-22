import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whatsapppp/common/repositories/common_blob_storage_repository.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/multimedia_editing/repository/media_repository.dart';
import 'package:whatsapppp/features/multimedia_editing/widgets/preview_panel.dart';

// State providers for media editing
final isEditingProvider = StateProvider<bool>((ref) => false);
final currentMediaFileProvider = StateProvider<File?>((ref) => null);
final editingProgressProvider = StateProvider<double>((ref) => 0.0);
final selectedFilterProvider = StateProvider<String?>((ref) => null);

// Controller provider
final mediaControllerProvider = Provider((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  final blobRepository = ref.watch(commonBlobStorageRepositoryProvider);
  return MediaController(
    mediaRepository: mediaRepository,
    blobRepository: blobRepository,
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
  final CommonBlobStorageRepository blobRepository;
  final Ref ref;

  MediaController({
    required this.mediaRepository,
    required this.blobRepository,
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

  // NEW: Save image as blob instead of Firebase Storage
  Future<String?> saveEditedImageToBlob({
    required File imageFile,
    required BuildContext context,
    String? originalFileName,
    String? projectId,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;

      // FIX: Get the actual authenticated user ID instead of hardcoded string
      final userId = mediaRepository.auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = originalFileName ?? 'edited_image_$timestamp.jpg';
      final blobPath = 'media/$userId/edited_images/$fileName';

      ref.read(editingProgressProvider.notifier).state = 0.5;

      // Store the image file as a blob
      final blobId = await blobRepository.storeFileAsBlob(
        blobPath,
        imageFile,
        context,
      );

      // IMPORTANT: Also save metadata to Firestore using MediaRepository method
      await mediaRepository.saveEditedImageToBlob(
        editedImageFile: imageFile,
        originalFileName: fileName,
        context: context,
        projectId: projectId,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;

      showSnackBar(context, 'Image saved as blob successfully');
      return blobId;
    } catch (e) {
      print('Failed to save image as blob: ${e.toString()}');
      showSnackBar(context, 'Failed to save image: ${e.toString()}');
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  Future<String?> saveEditedVideoToBlob({
    required File videoFile,
    required BuildContext context,
    String? originalFileName,
    String? projectId,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;

      final blobId = await mediaRepository.saveEditedVideoToBlob(
        editedVideoFile: videoFile,
        originalFileName: originalFileName ??
            'edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        context: context,
        projectId: projectId,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;
      return blobId;
    } catch (e) {
      showSnackBar(context, 'Failed to save video: $e');
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  // UPDATED: Save image with overlays rendered
  Future<String?> saveImageWithOverlays({
    required String originalImagePath,
    required List<OverlayItem> overlays,
    required BuildContext context,
    String? projectId,
  }) async {
    try {
      ref.read(isEditingProvider.notifier).state = true;
      ref.read(editingProgressProvider.notifier).state = 0.1;

      print('MediaController: Saving image with ${overlays.length} overlays');

      // If there are overlays, we need to render them onto the image
      File imageToSave;

      if (overlays.isNotEmpty) {
        print('MediaController: Rendering overlays onto image');
        ref.read(editingProgressProvider.notifier).state = 0.3;

        // Create a new image with overlays rendered
        imageToSave = await _renderOverlaysOnImage(
          originalImagePath: originalImagePath,
          overlays: overlays,
        );
      } else {
        // No overlays, use current edited image or original
        final currentFile = ref.read(currentMediaFileProvider);
        imageToSave = currentFile ?? File(originalImagePath);
      }

      ref.read(editingProgressProvider.notifier).state = 0.6;

      // Save using blob storage instead of Firebase Storage
      final blobId = await saveEditedImageToBlob(
        imageFile: imageToSave,
        context: context,
        originalFileName: 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
        projectId: projectId,
      );

      ref.read(editingProgressProvider.notifier).state = 1.0;
      ref.read(currentMediaFileProvider.notifier).state = imageToSave;

      if (blobId != null) {
        showSnackBar(context, 'Image with overlays saved successfully');
      }

      return blobId;
    } catch (e) {
      showSnackBar(
          context, 'Failed to save image with overlays: ${e.toString()}');
      return null;
    } finally {
      ref.read(isEditingProvider.notifier).state = false;
      ref.read(editingProgressProvider.notifier).state = 0.0;
    }
  }

  // IMPROVED: Render overlays on image using Flutter's painting system
  Future<File> _renderOverlaysOnImage({
    required String originalImagePath,
    required List<OverlayItem> overlays,
  }) async {
    try {
      print('MediaController: Starting overlay rendering');

      // Load the original image
      final originalFile = File(originalImagePath);
      final imageBytes = await originalFile.readAsBytes();
      final originalImage = await decodeImageFromList(imageBytes);

      print(
          'MediaController: Original image size: ${originalImage.width}x${originalImage.height}');

      // Create a picture recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the original image
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // Draw each overlay
      for (int i = 0; i < overlays.length; i++) {
        final overlay = overlays[i];
        print('MediaController: Rendering overlay $i: ${overlay.type}');

        await _drawOverlayOnCanvas(canvas, overlay,
            originalImage.width.toDouble(), originalImage.height.toDouble());
      }

      // Convert to image
      final picture = recorder.endRecording();
      final img =
          await picture.toImage(originalImage.width, originalImage.height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/edited_image_$timestamp.png');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      print(
          'MediaController: Overlay rendering completed, saved to: ${tempFile.path}');

      // Clean up
      originalImage.dispose();
      img.dispose();

      return tempFile;
    } catch (e) {
      print('MediaController: Error rendering overlays: $e');
      // If rendering fails, return the original file
      return File(originalImagePath);
    }
  }

  // Helper method to draw individual overlays on canvas
  Future<void> _drawOverlayOnCanvas(Canvas canvas, OverlayItem overlay,
      double imageWidth, double imageHeight) async {
    canvas.save();

    // Apply transformations
    canvas.translate(overlay.position.dx, overlay.position.dy);
    canvas.rotate(overlay.rotation);
    canvas.scale(overlay.scale);

    if (overlay.type == OverlayType.text) {
      // Draw text overlay
      final textStyle = TextStyle(
        fontSize: overlay.fontSize,
        color: overlay.color,
        fontWeight: (overlay.isBold) ? FontWeight.bold : FontWeight.normal,
        fontStyle: (overlay.isItalic) ? FontStyle.italic : FontStyle.normal,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      );

      final textSpan = TextSpan(text: overlay.content, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset.zero);
    } else if (overlay.type == OverlayType.sticker) {
      // Draw sticker overlay
      // You'll need to implement sticker loading and drawing
      // For now, draw a placeholder
      final paint = Paint()
        ..color = overlay.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset.zero, 20, paint);

      // Add text for sticker content
      if (overlay.content.isNotEmpty) {
        final textStyle = TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: overlay.content, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        textPainter.layout();
        textPainter.paint(
            canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      }
    }

    canvas.restore();
  }

  // UPDATED: Save current edited image using blob storage
  Future<String?> saveCurrentEditedImage({
    required BuildContext context,
    String? projectId,
    String? originalImagePath,
    List<OverlayItem>? overlays,
  }) async {
    final currentFile = ref.read(currentMediaFileProvider);

    // Check if we have overlays but no current file
    if (currentFile == null) {
      if (originalImagePath != null && (overlays?.isNotEmpty ?? false)) {
        // We have overlays on the original image
        showSnackBar(
            context, 'Saving original image with ${overlays!.length} overlays');

        return await saveImageWithOverlays(
          originalImagePath: originalImagePath,
          overlays: overlays,
          context: context,
          projectId: projectId,
        );
      } else if (originalImagePath != null) {
        // No overlays, save original image as blob
        return await saveEditedImageToBlob(
          imageFile: File(originalImagePath),
          context: context,
          originalFileName: originalImagePath.split('/').last,
          projectId: projectId,
        );
      } else {
        showSnackBar(context, 'No image to save');
        return null;
      }
    }

    // Save the current edited file
    return await saveEditedImageToBlob(
      imageFile: currentFile,
      context: context,
      originalFileName: currentFile.path.split('/').last,
      projectId: projectId,
    );
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
