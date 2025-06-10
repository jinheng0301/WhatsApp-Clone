import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimelineEditor extends ConsumerStatefulWidget {
  const TimelineEditor({super.key});

  @override
  ConsumerState<TimelineEditor> createState() => _TimelineEditorState();
}

class _TimelineEditorState extends ConsumerState<TimelineEditor> {
  double _startTrim = 0.0;
  double _endTrim = 1.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[800],
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Timeline scrubber
            Row(
              children: [
                Text('${(_startTrim * 30).toInt()}s'),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: RangeSlider(
                      values: RangeValues(_startTrim, _endTrim),
                      onChanged: (values) {
                        setState(() {
                          _startTrim = values.start;
                          _endTrim = values.end;
                        });
                      },
                    ),
                  ),
                ),
                Text('${(_endTrim * 30).toInt()}s'),
              ],
            ),
      
            // Timeline thumbnails (simplified)
            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child:
                    Text('Video Timeline', style: TextStyle(color: Colors.grey)),
              ),
            ),
      
            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
