import 'dart:io';

import 'package:enough_giphy_flutter/enough_giphy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void showSnackBar(BuildContext context, String content) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content),
    ),
  );
}

Future<File?> pickImageFromGallery(BuildContext context) async {
  File? image;

  try {
    // picking image from the source of gallery
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    // checking if picture is not equal to null
    // converting the image to file
    if (pickedImage != null) {
      image = File(pickedImage.path);
    }
  } catch (e) {
    showSnackBar(context, 'No image selected');
  }
  return image;
}

Future<File?> pickFromCamera(BuildContext context) async {
  File? image;

  try {
    // picking image from the source of gallery
    final pickedFromCamera = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    // checking if picture is not equal to null
    // converting the image to file
    if (pickedFromCamera != null) {
      image = File(pickedFromCamera.path);
    }
  } catch (e) {
    showSnackBar(context, 'No image selected');
  }
  return image;
}

Future<File?> pickVideoFromGallery(BuildContext context) async {
  File? video;
  try {
    final pickedVideo =
        await ImagePicker().pickVideo(source: ImageSource.gallery);

    if (pickedVideo != null) {
      video = File(pickedVideo.path);
    }
  } catch (e) {
    showSnackBar(context, e.toString());
  }
  return video;
}

Future<GiphyGif?> pickGIF(BuildContext context) async {
  GiphyGif? gif;
  try {
    gif = await Giphy.getGif(
      context: context,
      apiKey: 'pwXu0t7iuNVm8VO5bgND2NzwCpVH9S0F',
    );
  } catch (e) {
    showSnackBar(context, e.toString());
  }
  return gif;
}
