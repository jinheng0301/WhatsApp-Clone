import 'dart:io';
import 'package:flutter/material.dart';
import 'package:whatsapppp/common/utils/utils.dart';
import 'package:whatsapppp/features/multimedia_editing/services/media_editor_service.dart';

class ImageHandler {
  Future<void> showCropDialog(
    BuildContext context,
    String imagePath,
    Function(String newPath) onImageCropped,
  ) async {
    final croppedFile = await MediaEditorService.cropImage(imagePath);
    if (croppedFile != null) {
      onImageCropped(croppedFile.path);
      showSnackBar(context, 'Image cropped successfully!');
    }
  }

  Future<void> rotateImage(
    BuildContext context,
    String imagePath,
    int degrees,
    Function(String newPath) onImageRotated,
  ) async {
    final newPath = await MediaEditorService.rotateMedia(
      mediaPath: imagePath,
      degrees: degrees,
      isVideo: false,
    );
    onImageRotated(newPath);
    showSnackBar(context, 'Image rotated ${degrees}°');
  }

  Future<void> showRotationDialog(
    BuildContext context,
    String imagePath,
    Function(String newPath) onImageRotated,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.rotate_90_degrees_ccw, color: Colors.blue),
            SizedBox(width: 8),
            Text('Rotate Image'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose rotation angle:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _rotationButton(context, 90, '90°'),
                _rotationButton(context, 180, '180°'),
                _rotationButton(context, 270, '270°'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      await rotateImage(context, imagePath, result, onImageRotated);
    }
  }

  Widget _rotationButton(BuildContext context, int degrees, String label) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context, degrees),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rotate_90_degrees_ccw),
          SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  Future<void> applyFilter(
    BuildContext context,
    String imagePath,
    String filterType,
    Function(String newPath) onFilterApplied,
  ) async {
    if (filterType == 'original') return;

    final newPath = await MediaEditorService.applyFilter(
      mediaPath: imagePath,
      filterType: filterType,
      isVideo: false,
    );
    onFilterApplied(newPath);
    showSnackBar(context, 'Filter "$filterType" applied successfully!');
  }

  Future<void> showFilterDialog(
    BuildContext context,
    String imagePath,
    Function(String newPath) onFilterApplied,
  ) async {
    final filters = [
      ('Original', 'original', Colors.transparent),
      ('Vintage', 'vintage', Colors.orange.withOpacity(0.3)),
      ('B&W', 'grayscale', Colors.grey),
      ('Sepia', 'sepia', Colors.brown.withOpacity(0.3)),
      ('Vibrant', 'vibrant', Colors.purple.withOpacity(0.3)),
      ('Cool', 'cool', Colors.blue.withOpacity(0.3)),
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.filter, color: Colors.purple),
            SizedBox(width: 8),
            Text('Apply Filter'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  applyFilter(context, imagePath, filter.$2, onFilterApplied);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: filter.$3,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: filter.$2 == 'original'
                            ? const Icon(Icons.image, size: 30)
                            : Container(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        filter.$1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> showEffectDialog(
    BuildContext context,
    String imagePath,
    Function(String newPath) onEffectApplied,
  ) async {
    final effects = [
      ('Blur', Icons.blur_on, 'blur'),
      ('Brighten', Icons.brightness_high, 'brighten'),
      ('Darken', Icons.brightness_low, 'darken'),
      ('Contrast', Icons.contrast, 'contrast'),
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_fix_high, color: Colors.orange),
            SizedBox(width: 8),
            Text('Apply Effect'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: effects.length,
            itemBuilder: (context, index) {
              final effect = effects[index];
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  applyEffect(context, imagePath, effect.$3, onEffectApplied);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(effect.$2, size: 30, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text(
                        effect.$1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> applyEffect(
    BuildContext context,
    String imagePath,
    String effectType,
    Function(String newPath) onEffectApplied,
  ) async {
    // For now, we'll use the filter system to apply basic effects
    // In a real implementation, you'd have specific effect methods
    String filterType = effectType;

    final newPath = await MediaEditorService.applyFilter(
      mediaPath: imagePath,
      filterType: filterType,
      isVideo: false,
    );
    onEffectApplied(newPath);
    showSnackBar(context, 'Effect "$effectType" applied successfully!');
  }

  Future<void> duplicateImage(
    BuildContext context,
    String imagePath,
    Function(String newPath) onImageDuplicated,
  ) async {
    try {
      final directory = Directory(imagePath).parent;
      final fileName = imagePath.split('/').last;
      final extension = fileName.split('.').last;
      final nameWithoutExtension = fileName.replaceAll('.$extension', '');

      final outputPath =
          '${directory.path}/${nameWithoutExtension}_copy.$extension';

      // Copy the file
      await File(imagePath).copy(outputPath);

      onImageDuplicated(outputPath);
      showSnackBar(context, 'Image duplicated successfully!');
    } catch (e) {
      showSnackBar(context, 'Error duplicating image: $e');
    }
  }

  Future<void> showImageInfo(
    BuildContext context,
    String imagePath,
  ) async {
    try {
      final file = File(imagePath);
      final stats = await file.stat();
      final sizeInBytes = stats.size;
      final sizeInMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(2);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('Image Information'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File: ${imagePath.split('/').last}'),
              const SizedBox(height: 8),
              Text('Size: $sizeInMB MB'),
              const SizedBox(height: 8),
              Text('Modified: ${stats.modified.toString().split('.')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      showSnackBar(context, 'Error getting image info: $e');
    }
  }
}
