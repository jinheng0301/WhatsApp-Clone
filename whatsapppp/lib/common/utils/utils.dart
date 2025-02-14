import 'dart:io';

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

    // checking if picture i not equal to null
    // converting the image to file
    if (pickedImage != null) {
      image = File(pickedImage.path);
    }
  } catch (e) {
    showSnackBar(context, 'No image selected');
  }
  return image;
}
