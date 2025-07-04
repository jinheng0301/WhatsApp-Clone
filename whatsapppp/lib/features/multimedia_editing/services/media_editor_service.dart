import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

class MediaEditorService {
  // Crop image using ImageCropper
  static Future<File?> cropImage(String mediaPath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: mediaPath,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop'),
        IOSUiSettings(title: 'Crop')
      ],
    );
    return cropped != null ? File(cropped.path) : null;
  }

  // Apply filter to media
  static Future<String> applyFilter({
    required String mediaPath,
    required String filterType,
    required bool isVideo,
  }) async {
    final outputPath = '${mediaPath}_$filterType.${isVideo ? 'mp4' : 'jpg'}';

    if (isVideo) {
      await _applyVideoFilter(mediaPath, filterType, outputPath);
    } else {
      await _applyImageFilter(mediaPath, filterType, outputPath);
    }

    return outputPath;
  }

  static Future<String> applyEffect({
    required String mediaPath,
    required String effectType,
    required bool isVideo,
  }) async {
    final outputPath =
        '${mediaPath}_${effectType}_effect.${isVideo ? 'mp4' : 'jpg'}';

    if (isVideo) {
      await _applyVideoEffect(mediaPath, effectType, outputPath);
    } else {
      await _applyImageEffect(mediaPath, effectType, outputPath);
    }

    return outputPath;
  }

  static Future<String> trimVideo({
    required String inputPath,
    required Duration startTime,
    required Duration endTime,
  }) async {
    final outputPath = '${inputPath}_trimmed.mp4';

    // Calculate the duration of the trimmed video
    final duration = endTime - startTime;

    // Build FFmpeg command for trimming
    final command = '-i $inputPath '
        '-ss ${_formatDurationForFFmpeg(startTime)} '
        '-t ${_formatDurationForFFmpeg(duration)} '
        '-c copy $outputPath';

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        throw Exception('Failed to trim video. Return code: $returnCode');
      }
    } catch (e) {
      throw Exception('Error trimming video: $e');
    }
  }

  // Helper method to format Duration for FFmpeg
  static String _formatDurationForFFmpeg(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    int milliseconds = duration.inMilliseconds.remainder(1000);
    String threeDigitMilliseconds = milliseconds.toString().padLeft(3, "0");

    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds.$threeDigitMilliseconds";
  }

  static Future<void> _applyVideoEffect(
    String inputPath,
    String effectType,
    String outputPath,
  ) async {
    String command;

    switch (effectType) {
      case 'blur':
        command = '-i $inputPath -vf "boxblur=5:1" $outputPath';
        break;
      case 'brighten':
        command = '-i $inputPath -vf "eq=brightness=0.3" $outputPath';
        break;
      case 'darken':
        command = '-i $inputPath -vf "eq=brightness=-0.3" $outputPath';
        break;
      case 'contrast':
        command = '-i $inputPath -vf "eq=contrast=1.5" $outputPath';
        break;
      default:
        return;
    }

    await FFmpegKit.execute(command);
  }

  static Future<void> _applyVideoFilter(
    String inputPath,
    String filterType,
    String outputPath,
  ) async {
    String command;

    switch (filterType) {
      case 'vintage':
        command = '-i $inputPath -vf "curves=vintage" $outputPath';
        break;
      case 'grayscale':
        command = '-i $inputPath -vf "format=gray" $outputPath';
        break;
      case 'sepia':
        command =
            '-i $inputPath -vf "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131" $outputPath';
        break;
      case 'vibrant':
        command = '-i $inputPath -vf "eq=saturation=1.5" $outputPath';
        break;
      case 'cool':
        command =
            '-i $inputPath -vf "colorbalance=rs=-0.1:gs=0.1:bs=0.3" $outputPath';
        break;
      default:
        return;
    }

    await FFmpegKit.execute(command);
  }

  static Future<void> _applyImageEffect(
    String inputPath,
    String effectType,
    String outputPath,
  ) async {
    final bytes = await File(inputPath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return;

    switch (effectType) {
      case 'blur':
        // Apply Gaussian blur
        image = img.gaussianBlur(image, radius: 3);
        break;
      case 'brighten':
        // Increase brightness
        image = img.adjustColor(image, brightness: 1.3);
        break;
      case 'darken':
        // Decrease brightness
        image = img.adjustColor(image, brightness: 0.7);
        break;
      case 'contrast':
        // Increase contrast
        image = img.adjustColor(image, contrast: 1.5);
        break;
      default:
        return;
    }

    await File(outputPath).writeAsBytes(img.encodeJpg(image));
  }

  static Future<void> _applyImageFilter(
    String inputPath,
    String filterType,
    String outputPath,
  ) async {
    final bytes = await File(inputPath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return;

    switch (filterType) {
      case 'vintage':
      case 'sepia':
        image = img.sepia(image);
        break;
      case 'grayscale':
        image = img.grayscale(image);
        break;
      case 'vibrant':
        image = img.adjustColor(image, saturation: 1.5);
        break;
      case 'cool':
        image = img.colorOffset(image, blue: 30, red: -20);
        break;
      default:
        return;
    }

    await File(outputPath).writeAsBytes(img.encodeJpg(image));
  }

  // Rotate media
  static Future<String> rotateMedia({
    required String mediaPath,
    required int degrees,
    required bool isVideo,
  }) async {
    final outputPath = '${mediaPath}_rotated.${isVideo ? 'mp4' : 'jpg'}';

    if (isVideo) {
      await _rotateVideo(mediaPath, degrees, outputPath);
    } else {
      await _rotateImage(mediaPath, degrees, outputPath);
    }

    return outputPath;
  }

  static Future<void> _rotateVideo(
    String inputPath,
    int degrees,
    String outputPath,
  ) async {
    String transpose;

    switch (degrees) {
      case 90:
        transpose = 'transpose=1';
        break;
      case 180:
        transpose = 'transpose=2,transpose=2';
        break;
      case 270:
        transpose = 'transpose=2';
        break;
      default:
        return;
    }

    await FFmpegKit.execute('-i $inputPath -vf "$transpose" $outputPath');
  }

  static Future<void> _rotateImage(
    String inputPath,
    int degrees,
    String outputPath,
  ) async {
    final bytes = await File(inputPath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final rotated = img.copyRotate(image, angle: degrees);
    await File(outputPath).writeAsBytes(img.encodeJpg(rotated));
  }

  // Change video speed
  static Future<String> changeVideoSpeed({
    required String videoPath,
    required double speedFactor,
  }) async {
    final outputPath = '${videoPath}_speed.mp4';
    final command = '-i $videoPath -filter_complex '
        '"[0:v]setpts=${1 / speedFactor}*PTS[v];'
        '[0:a]atempo=$speedFactor[a]" '
        '-map "[v]" -map "[a]" $outputPath';

    await FFmpegKit.execute(command);
    return outputPath;
  }

  // Enhanced split video function that creates new video starting from split point
  static Future<List<String>> splitVideo({
    required String videoPath,
    required Duration splitPoint,
    Duration? originalStartOffset, // Track original start offset
  }) async {
    final firstHalf = '${videoPath}_part1.mp4';
    final secondHalf = '${videoPath}_part2.mp4';

    // First part: from beginning to split point
    await FFmpegKit.execute(
        '-i $videoPath -t ${splitPoint.inSeconds} -c copy $firstHalf');

    // Second part: from split point to end (this becomes the new "main" video)
    // Use -avoid_negative_ts make_zero to reset timestamps
    await FFmpegKit.execute(
        '-i $videoPath -ss ${splitPoint.inSeconds} -avoid_negative_ts make_zero -c copy $secondHalf');

    return [firstHalf, secondHalf];
  }

  // New function to get video metadata including duration
  static Future<Duration> getVideoDuration(String videoPath) async {
    // This would need to be implemented using FFprobe or video_player
    // For now, returning a placeholder
    return const Duration(seconds: 30);
  }

  // Additional video manipulation methods that might be useful
  // Merge/Concatenate videos
  static Future<String> mergeVideos({
    required List<String> videoPaths,
  }) async {
    if (videoPaths.isEmpty) throw Exception('No videos to merge');

    final outputPath = '${videoPaths.first}_merged.mp4';

    // Create a temporary file list for FFmpeg concat
    final listFile = File('${videoPaths.first}_list.txt');
    final listContent = videoPaths.map((path) => 'file \'$path\'').join('\n');
    await listFile.writeAsString(listContent);

    try {
      final command =
          '-f concat -safe 0 -i ${listFile.path} -c copy $outputPath';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        throw Exception('Failed to merge videos. Return code: $returnCode');
      }
    } finally {
      // Clean up temporary file
      if (await listFile.exists()) {
        await listFile.delete();
      }
    }
  }

  // Extract audio from video
  static Future<String> extractAudio({
    required String videoPath,
  }) async {
    final outputPath = '${videoPath}_audio.mp3';

    final command = '-i $videoPath -vn -acodec mp3 $outputPath';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      throw Exception('Failed to extract audio. Return code: $returnCode');
    }
  }

  // Add audio to video (replace existing audio)
  static Future<String> replaceVideoAudio({
    required String videoPath,
    required String audioPath,
  }) async {
    final outputPath = '${videoPath}_with_audio.mp4';

    final command =
        '-i $videoPath -i $audioPath -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 $outputPath';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      throw Exception('Failed to replace audio. Return code: $returnCode');
    }
  }

  // Adjust video volume
  static Future<String> adjustVolume({
    required String videoPath,
    required double
        volumeLevel, // 0.0 to 2.0 (0 = mute, 1 = normal, 2 = double)
  }) async {
    final outputPath =
        '${videoPath}_volume_${volumeLevel.toStringAsFixed(1)}.mp4';

    final command = '-i $videoPath -af "volume=$volumeLevel" $outputPath';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      throw Exception('Failed to adjust volume. Return code: $returnCode');
    }
  }

  // Create video thumbnail
  static Future<String> createThumbnail({
    required String videoPath,
    Duration? timeOffset,
  }) async {
    final outputPath = '${videoPath}_thumbnail.jpg';
    final offset = timeOffset ?? const Duration(seconds: 1);

    final command =
        '-i $videoPath -ss ${_formatDurationForFFmpeg(offset)} -vframes 1 $outputPath';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      throw Exception('Failed to create thumbnail. Return code: $returnCode');
    }
  }

  // ============ AUDIO FUNCTIONS ============

  /// Add background music to video with volume control
  static Future<String?> addBackgroundMusic({
    required String videoPath,
    required String audioPath,
    double audioVolume = 0.5,
    double videoVolume = 1.0,
    bool loopAudio = false,
  }) async {
    try {
      final outputPath = '${videoPath}_with_music.mp4';

      String command = '-i "$videoPath" -i "$audioPath" ';

      if (loopAudio) {
        // Loop audio to match video duration
        command += '-filter_complex '
            '"[1:a]aloop=loop=-1:size=2e+09[alooped];'
            '[0:a]volume=$videoVolume[v0];'
            '[alooped]volume=$audioVolume[v1];'
            '[v0][v1]amix=inputs=2:duration=first[aout]" '
            '-map 0:v -map "[aout]" -c:v copy -c:a aac "$outputPath"';
      } else {
        command += '-filter_complex '
            '"[0:a]volume=$videoVolume[v0];'
            '[1:a]volume=$audioVolume[v1];'
            '[v0][v1]amix=inputs=2:duration=shortest[aout]" '
            '-map 0:v -map "[aout]" -c:v copy -c:a aac "$outputPath"';
      }

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print('Error adding background music: $e');
      return null;
    }
  }

  /// Mute original audio from video
  static Future<String?> muteOriginalAudio(String videoPath) async {
    try {
      final outputPath = '${videoPath}_muted.mp4';
      final command = '-i "$videoPath" -c:v copy -an "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print('Error muting audio: $e');
      return null;
    }
  }

  /// Adjust original audio volume
  static Future<String?> adjustOriginalAudioVolume({
    required String videoPath,
    required double volumeLevel,
  }) async {
    try {
      final outputPath = '${videoPath}_volume_adjusted.mp4';
      final command =
          '-i "$videoPath" -filter:a "volume=$volumeLevel" -c:v copy "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print('Error adjusting volume: $e');
      return null;
    }
  }

  /// Add voice over to video
  static Future<String?> addVoiceOver({
    required String videoPath,
    required String voiceOverPath,
    double voiceVolume = 1.0,
    double originalVolume = 0.3,
  }) async {
    try {
      final outputPath = '${videoPath}_with_voiceover.mp4';
      final command = '-i "$videoPath" -i "$voiceOverPath" '
          '-filter_complex "[0:a]volume=$originalVolume[v0];'
          '[1:a]volume=$voiceVolume[v1];'
          '[v0][v1]amix=inputs=2:duration=first[aout]" '
          '-map 0:v -map "[aout]" -c:v copy -c:a aac "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print('Error adding voice over: $e');
      return null;
    }
  }

  /// Extract audio from video
  static Future<String?> extractAudioFromVideo(String videoPath) async {
    try {
      final outputPath = '${videoPath}_extracted_audio.aac';
      final command = '-i "$videoPath" -vn -acodec copy "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print('Error extracting audio: $e');
      return null;
    }
  }

  /// Add fade in/out effects to audio
  static Future<String?> addAudioFade({
    required String audioPath,
    double fadeInDuration = 2.0,
    double fadeOutDuration = 2.0,
  }) async {
    try {
      final outputPath = '${audioPath}_faded.aac';
      final command = '-i "$audioPath" '
          '-filter:a "afade=t=in:ss=0:d=$fadeInDuration,afade=t=out:st=${fadeOutDuration * -1}:d=$fadeOutDuration" '
          '"$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print('Error adding audio fade: $e');
      return null;
    }
  }

  /// Trim audio to specific duration
  static Future<String?> trimAudio({
    required String audioPath,
    required Duration startTime,
    required Duration endTime,
  }) async {
    try {
      final outputPath = '${audioPath}_trimmed.aac';
      final duration = endTime.inSeconds - startTime.inSeconds;
      final command =
          '-i "$audioPath" -ss ${startTime.inSeconds} -t $duration -c copy "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print('Error trimming audio: $e');
      return null;
    }
  }

  /// Replace audio in video with new audio
  static Future<String?> replaceAudioInVideo({
    required String videoPath,
    required String audioPath,
  }) async {
    try {
      final outputPath = '${videoPath}_with_new_audio.mp4';
      final command =
          '-i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print('Error replacing audio: $e');
      return null;
    }
  }

  /// Get audio duration
  static Future<Duration?> getAudioDuration(String mediaPath) async {
    try {
      // This would need proper implementation using ffprobe or similar
      // For now, returning a default duration
      return const Duration(seconds: 30);
    } catch (e) {
      print('Error getting audio duration: $e');
      return null;
    }
  }
}
