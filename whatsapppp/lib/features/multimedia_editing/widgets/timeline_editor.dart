import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimelineEditor extends ConsumerStatefulWidget {
  final String? videoPath;
  final Function(Duration, Duration)? onTrimChanged;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final Function(Duration)? onSeek;

  const TimelineEditor({
    super.key,
    this.videoPath,
    this.onTrimChanged,
    this.onPlay,
    this.onPause,
    this.onSeek,
  });

  @override
  ConsumerState<TimelineEditor> createState() => TimelineEditorState();
}

class TimelineEditorState extends ConsumerState<TimelineEditor> {
  double _startTrim = 0.0;
  double _endTrim = 1.0;
  double _currentPosition = 0.0;
  Duration _videoDuration = const Duration(seconds: 30); // Default
  Duration _videoStartOffset = Duration.zero; // Track split offset

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.videoPath != null) {
      _loadVideoInfo();
    }
    _startPositionTimer();
  }

  void _startPositionTimer() {}

  // Method to update timeline when video is split
  void updateForSplitVideo(Duration originalSplitPoint, Duration newDuration) {
    setState(() {
      _videoStartOffset = originalSplitPoint;
      _videoDuration = newDuration;
      _currentPosition = 0.0;
      _startTrim = 0.0;
      _endTrim = 1.0;
    });
  }

  // 3. Modified TimelineEditor - Add method to get actual timeline position
  String _getActualTimeFromPosition(double normalizedPosition) {
    final videoTime = Duration(
      seconds: (normalizedPosition * _videoDuration.inSeconds).round(),
    );
    final actualTime = Duration(
      milliseconds: videoTime.inMilliseconds + _videoStartOffset.inMilliseconds,
    );
    return _formatDuration(actualTime);
  }

  Future<void> _loadVideoInfo() async {
    // In a real implementation, you'd get video duration from video_player
    // For now, using a placeholder
    setState(() {
      _videoDuration = const Duration(seconds: 30);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current position indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video: ${_formatDuration(Duration(
                        seconds: (_currentPosition * _videoDuration.inSeconds)
                            .round(),
                      ))}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (_videoStartOffset > Duration.zero)
                      Text(
                        'Original: ${_getActualTimeFromPosition(_currentPosition)}',
                        style:
                            const TextStyle(color: Colors.green, fontSize: 10),
                      ),
                  ],
                ),
                Text(
                  'Duration: ${_formatDuration(_videoDuration)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Timeline info banner for split videos
            if (_videoStartOffset > Duration.zero)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Split Video Timeline',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Original start: ${_formatDuration(_videoStartOffset)}',
                      style: const TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                    Text(
                      'Current range: ${_formatDuration(_videoStartOffset)} - ${_formatDuration(Duration(milliseconds: _videoStartOffset.inMilliseconds + _videoDuration.inMilliseconds))}',
                      style: const TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  ],
                ),
              ),

            // Main timeline scrubber
            Column(
              children: [
                // Position scrubber
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.grey,
                    thumbColor: Colors.blue,
                  ),
                  child: Slider(
                    value: _currentPosition,
                    onChanged: (value) {
                      setState(() => _currentPosition = value);
                      // In real implementation, seek video to this position
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Timeline info
                if (_videoStartOffset > Duration.zero)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Split video - Original start: ${_formatDuration(_videoStartOffset)}',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),

                // Trim range slider
                Text(
                  'Trim: ${_formatDuration(Duration(seconds: (_startTrim * _videoDuration.inSeconds).round()))} - ${_formatDuration(Duration(seconds: (_endTrim * _videoDuration.inSeconds).round()))}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                    activeTrackColor: Colors.green,
                    inactiveTrackColor: Colors.grey,
                  ),
                  child: RangeSlider(
                    values: RangeValues(_startTrim, _endTrim),
                    onChanged: (values) {
                      setState(() {
                        _startTrim = values.start;
                        _endTrim = values.end;
                      });

                      // Notify parent about trim changes
                      if (widget.onTrimChanged != null) {
                        widget.onTrimChanged!(
                          Duration(
                            seconds:
                                (_startTrim * _videoDuration.inSeconds).round(),
                          ),
                          Duration(
                            seconds:
                                (_endTrim * _videoDuration.inSeconds).round(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            // Video thumbnail timeline (placeholder)
            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[600]!),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[800],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Video Timeline Thumbnails',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Position indicator on timeline
                  Positioned(
                    left: _currentPosition *
                        (MediaQuery.of(context).size.width - 32),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.red,
                    ),
                  ),
                  // Trim indicators
                  Positioned(
                    left: _startTrim * (MediaQuery.of(context).size.width - 32),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: Colors.green,
                    ),
                  ),
                  Positioned(
                    left: _endTrim * (MediaQuery.of(context).size.width - 32),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
