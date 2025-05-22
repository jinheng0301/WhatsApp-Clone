import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MemoryManager {
  static const int _maxMemoryUsage = 50 * 1024 * 1024; // 50MB
  static int _currentMemoryUsage = 0;
  static final Map<String, Uint8List> _cache = {};
  static const int _maxCacheSize = 20 * 1024 * 1024; // 20MB cache

  // Check if we can safely load a file of given size
  static bool canLoadFile(int fileSize) {
    return (_currentMemoryUsage + fileSize) < _maxMemoryUsage;
  }

  // Add data to cache with memory management
  static void addToCache(String key, Uint8List data) {
    final dataSize = data.length;

    // Check if adding this would exceed cache limit
    while (_getCacheSize() + dataSize > _maxCacheSize && _cache.isNotEmpty) {
      // Remove oldest entry
      final firstKey = _cache.keys.first;
      final removedData = _cache.remove(firstKey);
      if (removedData != null) {
        _currentMemoryUsage -= removedData.length;
      }
    }

    _cache[key] = data;
    _currentMemoryUsage += dataSize;
  }

  // Get data from cache
  static Uint8List? getFromCache(String key) {
    return _cache[key];
  }

  // Remove from cache
  static void removeFromCache(String key) {
    final data = _cache.remove(key);
    if (data != null) {
      _currentMemoryUsage -= data.length;
    }
  }

  // Clear all cache
  static void clearCache() {
    _cache.clear();
    _currentMemoryUsage = 0;
    // Garbage collection is managed automatically in Dart.
  }

  // Get current cache size
  static int _getCacheSize() {
    return _cache.values.fold(0, (sum, data) => sum + data.length);
  }

  // Get memory statistics
  static Map<String, dynamic> getMemoryStats() {
    return {
      'currentUsage': _currentMemoryUsage,
      'maxUsage': _maxMemoryUsage,
      'cacheSize': _getCacheSize(),
      'maxCacheSize': _maxCacheSize,
      'cachedItems': _cache.length,
      'usagePercentage':
          ((_currentMemoryUsage / _maxMemoryUsage) * 100).toStringAsFixed(1),
    };
  }

  // Check if memory is running low
  static bool isMemoryLow() {
    return _currentMemoryUsage > (_maxMemoryUsage * 0.8); // 80% threshold
  }

  // Force cleanup when memory is low
  static Future<void> emergencyCleanup() async {
    print('MemoryManager: Emergency cleanup triggered');

    // Clear half of the cache, starting with largest items
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final itemsToRemove = (sortedEntries.length / 2).ceil();
    for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
      removeFromCache(sortedEntries[i].key);
    }

    // Clear temporary files
    await _clearTempFiles();

    // Force garbage collection
    // Garbage collection is managed automatically in Dart.

    // Wait a bit for cleanup to complete
    await Future.delayed(const Duration(milliseconds: 100));
    print('MemoryManager: Emergency cleanup completed');
  }

  // Clear temporary files
  static Future<void> _clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await for (final file in tempDir.list()) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          // Remove temporary media files
          if (fileName.contains('temp_') ||
              fileName.contains('compressed_') ||
              fileName.contains('cache_')) {
            try {
              await file.delete();
            } catch (e) {
              print('MemoryManager: Error deleting temp file: $e');
            }
          }
        }
      }
    } catch (e) {
      print('MemoryManager: Error clearing temp files: $e');
    }
  }

  // Safe file reader with memory checks
  static Future<Uint8List?> safeReadFile(File file) async {
    try {
      if (!await file.exists()) {
        return null;
      }

      final fileSize = await file.length();

      // Check if file is too large
      if (fileSize > _maxMemoryUsage / 2) {
        print('MemoryManager: File too large to read safely: $fileSize bytes');
        return null;
      }

      // Check if we have enough memory
      if (!canLoadFile(fileSize)) {
        // Try cleanup first
        if (isMemoryLow()) {
          await emergencyCleanup();
        }

        // Check again after cleanup
        if (!canLoadFile(fileSize)) {
          print('MemoryManager: Not enough memory to load file');
          return null;
        }
      }

      final data = await file.readAsBytes();
      _currentMemoryUsage += data.length;

      return data;
    } catch (e) {
      print('MemoryManager: Error reading file safely: $e');
      return null;
    }
  }

  // Safe base64 decoder with memory checks
  static Uint8List? safeBase64Decode(String base64String) {
    try {
      final estimatedSize = (base64String.length * 3) ~/ 4;

      // Check if decoded data would be too large
      if (estimatedSize > _maxMemoryUsage / 2) {
        print('MemoryManager: Base64 data too large: $estimatedSize bytes');
        return null;
      }

      // Check if we have enough memory
      if (!canLoadFile(estimatedSize)) {
        print('MemoryManager: Not enough memory for base64 decode');
        return null;
      }

      final data = base64Decode(base64String);
      _currentMemoryUsage += data.length;

      return data;
    } catch (e) {
      print('MemoryManager: Error decoding base64 safely: $e');
      return null;
    }
  }

  // Monitor memory usage and perform cleanup if needed
  static Future<void> monitorMemory() async {
    if (isMemoryLow()) {
      print(
          'MemoryManager: Memory usage high (${getMemoryStats()['usagePercentage']}%)');

      // Clear oldest cache entries
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)); // Assuming key has timestamp

      final itemsToRemove = (_cache.length * 0.3).ceil(); // Remove 30%
      for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
        removeFromCache(sortedEntries[i].key);
      }
    }
  }

  // Initialize memory manager
  static void initialize() {
    print(
        'MemoryManager: Initialized with ${(_maxMemoryUsage / (1024 * 1024)).toStringAsFixed(1)}MB limit');
  }

  // Dispose and cleanup
  static void dispose() {
    clearCache();
    print('MemoryManager: Disposed');
  }
}

// Extension to add memory-safe methods to File class
extension SafeFileOperations on File {
  Future<Uint8List?> readBytesSafely() async {
    return await MemoryManager.safeReadFile(this);
  }
}

// Mixin for widgets that use media files
mixin MediaMemoryManagement {
  void checkMemoryBeforeLoad() {
    if (MemoryManager.isMemoryLow()) {
      MemoryManager.emergencyCleanup();
    }
  }

  void disposeMediaMemory() {
    MemoryManager.monitorMemory();
  }
}
