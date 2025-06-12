import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
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

  // Split video
  static Future<List<String>> splitVideo({
    required String videoPath,
    required Duration splitPoint,
  }) async {
    final firstHalf = '${videoPath}_part1.mp4';
    final secondHalf = '${videoPath}_part2.mp4';

    await FFmpegKit.execute(
        '-i $videoPath -t ${splitPoint.inSeconds} -c copy $firstHalf');

    await FFmpegKit.execute(
        '-i $videoPath -ss ${splitPoint.inSeconds} -c copy $secondHalf');

    return [firstHalf, secondHalf];
  }
}
