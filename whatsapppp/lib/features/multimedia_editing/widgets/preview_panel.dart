import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

// Model for overlay items
class OverlayItem {
  final String id;
  final String content;
  final OverlayType type;
  Offset position;
  double fontSize;
  Color color;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool isSelected;

  OverlayItem({
    required this.id,
    required this.content,
    required this.type,
    required this.position,
    this.fontSize = 24.0,
    this.color = Colors.white,
    this.fontFamily = 'Roboto',
    this.isBold = false,
    this.isItalic = false,
    this.isSelected = false,
  });
}

enum OverlayType { text, sticker }

class PreviewPanel extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final Function(List<OverlayItem>)? onOverlaysChanged;

  const PreviewPanel({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    this.onOverlaysChanged,
  });

  @override
  State<PreviewPanel> createState() => PreviewPanelState();
}

class PreviewPanelState extends State<PreviewPanel> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  List<OverlayItem> _overlayItems = [];
  OverlayItem? _selectedItem;
  Size _previewSize = Size.zero;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.file(File(widget.mediaPath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Method to add text overlay
  void addTextOverlay({
    required String text,
    double fontSize = 24.0,
    Color color = Colors.white,
    String fontFamily = 'Roboto',
    bool isBold = false,
    bool isItalic = false,
  }) {
    final newItem = OverlayItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: OverlayType.text,
      position: Offset(_previewSize.width * 0.1, _previewSize.height * 0.1),
      fontSize: fontSize,
      color: color,
      fontFamily: fontFamily,
      isBold: isBold,
      isItalic: isItalic,
    );

    setState(() {
      _overlayItems.add(newItem);
      _selectedItem = newItem;
    });

    widget.onOverlaysChanged?.call(_overlayItems);
  }

  // Method to add sticker overlay
  void addStickerOverlay(String sticker) {
    final newItem = OverlayItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: sticker,
      type: OverlayType.sticker,
      position: Offset(_previewSize.width * 0.2, _previewSize.height * 0.2),
      fontSize: 48.0,
    );

    setState(() {
      _overlayItems.add(newItem);
      _selectedItem = newItem;
    });

    widget.onOverlaysChanged?.call(_overlayItems);
  }

  // Method to remove selected overlay
  void removeSelectedOverlay() {
    if (_selectedItem != null) {
      setState(() {
        _overlayItems.removeWhere((item) => item.id == _selectedItem!.id);
        _selectedItem = null;
      });
      widget.onOverlaysChanged?.call(_overlayItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _previewSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Container(
          color: Colors.black,
          child: GestureDetector(
            onTap: () {
              // Deselect all items when tapping on empty space
              setState(() {
                _selectedItem = null;
                for (var item in _overlayItems) {
                  item.isSelected = false;
                }
              });
            },
            child: Stack(
              children: [
                // Media content
                widget.isVideo ? _buildVideoPreview() : _buildImagePreview(),

                // Overlay items
                ..._overlayItems.map((item) => _buildDraggableOverlay(item)),

                // Delete button for selected item
                if (_selectedItem != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.red,
                      onPressed: removeSelectedOverlay,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableOverlay(OverlayItem item) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: Draggable(
        data: item,
        onDragEnd: (details) {
          setState(() {
            // Update position ensuring it stays within bounds
            final newX = details.offset.dx.clamp(0.0, _previewSize.width - 100);
            final newY = details.offset.dy.clamp(0.0, _previewSize.height - 50);
            item.position = Offset(newX, newY);
          });
          widget.onOverlaysChanged?.call(_overlayItems);
        },
        feedback: Material(
          color: Colors.transparent,
          child: _buildOverlayContent(item, isDragging: true),
        ),
        childWhenDragging: Container(),
        child: GestureDetector(
          onTap: () {
            setState(() {
              // Deselect all items first
              for (var overlayItem in _overlayItems) {
                overlayItem.isSelected = false;
              }
              // Select this item
              item.isSelected = true;
              _selectedItem = item;
            });
          },
          onScaleUpdate: (details) {
            // Handle pinch-to-zoom for text size
            if (item.type == OverlayType.text && details.scale != 1.0) {
              setState(() {
                item.fontSize =
                    (item.fontSize * details.scale).clamp(12.0, 72.0);
              });
            } else if (item.type == OverlayType.sticker &&
                details.scale != 1.0) {
              setState(() {
                item.fontSize =
                    (item.fontSize * details.scale).clamp(20.0, 100.0);
              });
            }
          },
          child: Container(
            decoration: item.isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: _buildOverlayContent(item),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent(OverlayItem item, {bool isDragging = false}) {
    if (item.type == OverlayType.sticker) {
      return Text(
        item.content,
        style: TextStyle(
          fontSize: item.fontSize,
          shadows: isDragging
              ? [
                  const Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ]
              : null,
        ),
      );
    } else {
      return Text(
        item.content,
        style: GoogleFonts.getFont(
          item.fontFamily,
          fontSize: item.fontSize,
          color: item.color,
          fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: item.isItalic ? FontStyle.italic : FontStyle.normal,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.7),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            if (!_isPlaying)
              IconButton(
                onPressed: _togglePlayPause,
                icon: const Icon(
                  Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Image.file(
        File(widget.mediaPath),
        fit: BoxFit.contain,
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  // Getter for overlay items (for external access)
  List<OverlayItem> get overlayItems => _overlayItems;
}
