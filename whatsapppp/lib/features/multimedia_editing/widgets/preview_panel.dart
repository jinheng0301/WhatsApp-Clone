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
  double rotation;
  double scale;

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
    this.rotation = 0.0,
    this.scale = 1.0,
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
  // Variables for gesture handling
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  Offset _initialFocalPoint = Offset.zero;

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
      rotation: 0.0, // Initialize with no rotation
      scale: 1.0, // Initialize with normal scale
    );

    setState(() {
      _overlayItems.add(newItem);
      _selectedItem = newItem;
      newItem.isSelected = true;
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
      rotation: 0.0, // Initialize with no rotation
      scale: 1.0, // Initialize with normal scale
    );

    setState(() {
      _overlayItems.add(newItem);
      _selectedItem = newItem;
      newItem.isSelected = true;
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
        onScaleStart: (details) {
          if (!item.isSelected) return;
          _initialScale = item.scale;
          _initialRotation = item.rotation;
          _initialFocalPoint = details.focalPoint;
        },
        onScaleUpdate: (details) {
          if (!item.isSelected) return;

          setState(() {
            // Handle scaling (pinch to zoom)
            if (details.scale != 1.0) {
              final newScale = (_initialScale * details.scale).clamp(0.3, 4.0);
              item.scale = newScale;
            }

            // Handle rotation (twist gesture)
            if (details.rotation != 0.0) {
              item.rotation = _initialRotation + details.rotation;
            }

            // Handle translation during scaling
            final delta = details.focalPoint - _initialFocalPoint;
            final newX = (item.position.dx + delta.dx * 0.5)
                .clamp(0.0, _previewSize.width - 100);
            final newY = (item.position.dy + delta.dy * 0.5)
                .clamp(0.0, _previewSize.height - 50);
            item.position = Offset(newX, newY);
          });
          widget.onOverlaysChanged?.call(_overlayItems);
        },
        onScaleEnd: (details) {
        },
        child: Transform.rotate(
          angle: item.rotation,
          child: Transform.scale(
            scale: item.scale,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: item.isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildOverlayContent(item),
                  // Show control handles when selected
                  if (item.isSelected) ..._buildCapCutStyleControls(item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCapCutStyleControls(OverlayItem item) {
    const double handleSize = 24.0;
    const double handleOffset = 12.0;

    return [
      // Top-left corner: Rotation handle
      Positioned(
        top: -handleOffset,
        left: -handleOffset,
        child: GestureDetector(
          onPanStart: (details) {
            _initialRotation = item.rotation;
          },
          onPanUpdate: (details) {
            // Calculate rotation based on movement around the center
            final center = Offset(item.scale * 50, item.scale * 25);
            final startVector = details.localPosition - center;
            final angle = startVector.direction;

            setState(() {
              item.rotation = angle;
            });
            widget.onOverlaysChanged?.call(_overlayItems);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.rotate_right,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Top-right corner: Scale/resize handle
      Positioned(
        top: -handleOffset,
        right: -handleOffset,
        child: GestureDetector(
          onPanStart: (details) {
            _initialScale = item.scale;
            _initialFocalPoint = details.globalPosition;
          },
          onPanUpdate: (details) {
            // Calculate scale based on distance change
            final currentPoint = details.globalPosition;
            final initialDistance = _initialFocalPoint.distance;
            final currentDistance = currentPoint.distance;
            final scaleChange = currentDistance / initialDistance;

            setState(() {
              final newScale = (_initialScale * scaleChange).clamp(0.3, 4.0);
              item.scale = newScale;
            });
            widget.onOverlaysChanged?.call(_overlayItems);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.zoom_out_map,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Bottom-left corner: Additional rotation handle (for easier access)
      Positioned(
        bottom: -handleOffset,
        left: -handleOffset,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Simple rotation based on horizontal movement
              item.rotation += details.delta.dx * 0.02;
            });
            widget.onOverlaysChanged?.call(_overlayItems);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.refresh,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Bottom-right corner: Scale handle (alternative)
      Positioned(
        bottom: -handleOffset,
        right: -handleOffset,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Scale based on diagonal movement
              final delta = details.delta.dx + details.delta.dy;
              final scaleChange = 1.0 + (delta * 0.0003);
              final newScale = (item.scale * scaleChange).clamp(0.3, 4.0);
              item.scale = newScale;
            });
            widget.onOverlaysChanged?.call(_overlayItems);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.open_in_full,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // Center delete button
      Positioned(
        top: -handleOffset * 2,
        right: 0,
        left: 0,
        child: Center(
          child: GestureDetector(
            onTap: removeSelectedOverlay,
            child: Container(
              width: handleSize,
              height: handleSize,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.delete,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  // List<Widget> _buildControlHandles(OverlayItem item) {
  //   return [
  //     // Rotation handle (top-right)
  //     Positioned(
  //       top: -10,
  //       right: -10,
  //       child: GestureDetector(
  //         onPanUpdate: (details) {
  //           // Calculate rotation based on pan movement
  //           final center = Offset(50, 25); // Approximate center of text
  //           final vector = details.localPosition - center;
  //           final angle = vector.direction;

  //           setState(() {
  //             item.rotation = angle;
  //           });
  //           widget.onOverlaysChanged?.call(_overlayItems);
  //         },
  //         child: Container(
  //           width: 20,
  //           height: 20,
  //           decoration: BoxDecoration(
  //             color: Colors.blue,
  //             shape: BoxShape.circle,
  //             border: Border.all(color: Colors.white, width: 1),
  //           ),
  //           child: const Icon(
  //             Icons.rotate_right,
  //             size: 12,
  //             color: Colors.white,
  //           ),
  //         ),
  //       ),
  //     ),

  //     // Scale handle (bottom-right)
  //     Positioned(
  //       bottom: -10,
  //       right: -10,
  //       child: GestureDetector(
  //         onPanUpdate: (details) {
  //           // Calculate scale based on distance from center
  //           final distance = details.localPosition.distance;
  //           final scaleFactor = (distance / 50).clamp(0.5, 3.0);

  //           setState(() {
  //             item.scale = scaleFactor;
  //           });
  //           widget.onOverlaysChanged?.call(_overlayItems);
  //         },
  //         child: Container(
  //           width: 20,
  //           height: 20,
  //           decoration: BoxDecoration(
  //             color: Colors.green,
  //             shape: BoxShape.circle,
  //             border: Border.all(color: Colors.white, width: 1),
  //           ),
  //           child: const Icon(
  //             Icons.open_in_full,
  //             size: 12,
  //             color: Colors.white,
  //           ),
  //         ),
  //       ),
  //     ),
  //   ];
  // }

  Widget _buildOverlayContent(OverlayItem item, {bool isDragging = false}) {
    Widget content;

    if (item.type == OverlayType.sticker) {
      content = Text(
        item.content,
        style: TextStyle(
          fontSize: item.fontSize,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      );
    } else {
      content = Text(
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: isDragging
          ? BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: content,
    );
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
