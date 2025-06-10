// new_project_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'confirmation_screen.dart';

class NewProjectScreen extends ConsumerStatefulWidget {
  static const routeName = '/new-project';
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Project'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Create New',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                _buildMediaOption(
                  icon: Icons.photo,
                  label: 'Photo',
                  onTap: () => _pickMedia(context, ref, isVideo: false),
                ),
                _buildMediaOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: () => _pickMedia(context, ref, isVideo: true),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Recent Projects', style: TextStyle(fontSize: 18)),
          ),
          // Recent projects list would go here
        ],
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(BuildContext context, WidgetRef ref,
      {required bool isVideo}) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = isVideo
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source);

      if (pickedFile != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(
              mediaPath: pickedFile.path,
              isVideo: isVideo,
            ),
          ),
        );
      }
    }
  }
}
