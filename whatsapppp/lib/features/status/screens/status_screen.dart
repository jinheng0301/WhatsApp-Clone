import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapppp/models/status_model.dart';
import 'package:story_view/story_view.dart';
import 'package:whatsapppp/features/status/controller/status_controller.dart';

class StatusScreen extends ConsumerStatefulWidget {
  static const String routeName = '/status-screen';
  final Status status;

  StatusScreen({required this.status});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  StoryController storyController = StoryController();
  List<StoryItem> storyItems = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initStoryPageItems();
  }

  void initStoryPageItems() async {
    try {
      print(
          'StatusScreen: Loading ${widget.status.photoUrl.length} story items');

      for (int i = 0; i < widget.status.photoUrl.length; i++) {
        final photoUrlOrBlobId = widget.status.photoUrl[i];

        // Check if it's a URL or blob ID
        if (photoUrlOrBlobId.startsWith('http')) {
          // It's a regular URL
          storyItems.add(StoryItem.pageImage(
            url: photoUrlOrBlobId,
            controller: storyController,
          ));
        } else {
          // It's a blob ID, fetch the blob data
          print('StatusScreen: Fetching blob data for ID: $photoUrlOrBlobId');

          final blobData = await ref
              .read(statusControllerProvider)
              .getStatusBlobData(photoUrlOrBlobId);

          if (blobData != null && blobData['data'] != null) {
            // Convert base64 to image
            final base64String = blobData['data'] as String;
            final imageBytes = base64Decode(base64String);

            // Create StoryItem with image bytes
            storyItems.add(StoryItem.pageImage(
              url: '', // Empty URL since we're using bytes
              controller: storyController,
              // Use a custom widget for displaying the image
              loadingWidget: Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                ),
              ),
            ));
          } else {
            print(
                'StatusScreen: Failed to load blob data for ID: $photoUrlOrBlobId');
            // Add error item
            storyItems.add(StoryItem.text(
              title: 'Failed to load image',
              backgroundColor: Colors.red,
            ));
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('StatusScreen: Error loading story items: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading status: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading status...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.white, size: 50),
              SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: storyItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 50),
                  SizedBox(height: 16),
                  Text("No status available"),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            )
          : StoryView(
              storyItems: storyItems,
              controller: storyController,
              onVerticalSwipeComplete: (direction) {
                if (direction == Direction.down) {
                  Navigator.pop(context);
                }
              },
              onComplete: () {
                Navigator.pop(context);
              },
              repeat: false,
            ),
    );
  }
}
