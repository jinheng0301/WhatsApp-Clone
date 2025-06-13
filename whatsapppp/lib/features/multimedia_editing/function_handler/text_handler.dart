import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whatsapppp/common/widgets/emoji_stickers.dart';

class TextHandler {
  final TextEditingController _textController = TextEditingController();
  Color _selectedTextColor = Colors.white;
  double _textSize = 24.0;
  bool _isBold = false;
  bool _isItalic = false;
  String _selectedFont = 'Roboto';

  final List<String> _availableFonts = ['Roboto', 'Lobster', 'Pacifico'];

  void dispose() {
    _textController.dispose();
  }

  Future<void> showTextEditor(
    BuildContext context,
    Function(
      String text,
      double fontSize,
      Color color,
      String fontFamily,
      bool isBold,
      bool isItalic,
    ) onTextAdded,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.text_fields, color: Colors.blue),
            SizedBox(width: 8),
            Text('Add Text'),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(children: [
                // Text input
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type your text here...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Font dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFont,
                  decoration: const InputDecoration(labelText: 'Font Family'),
                  items: _availableFonts
                      .map(
                        (font) => DropdownMenuItem(
                          value: font,
                          child: Text(font, style: GoogleFonts.getFont(font)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFont = value!),
                ),
                const SizedBox(height: 16),

                // Size slider
                Text('Size: ${_textSize.round()}px'),
                Slider(
                  value: _textSize,
                  min: 12.0,
                  max: 80.0,
                  onChanged: (value) => setState(() => _textSize = value),
                ),

                // Style checkboxes
                Row(children: [
                  Checkbox(
                    value: _isBold,
                    onChanged: (v) => setState(() => _isBold = v!),
                  ),
                  const Text('Bold'),
                  Checkbox(
                    value: _isItalic,
                    onChanged: (v) => setState(() => _isItalic = v!),
                  ),
                  const Text('Italic'),
                ]),

                // Color picker
                Wrap(
                  children: [
                    Colors.white,
                    Colors.black,
                    Colors.red,
                    Colors.blue,
                    Colors.green
                  ]
                      .map(
                        (color) => GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTextColor = color),
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedTextColor == color
                                    ? Colors.blue
                                    : Colors.grey,
                                width: _selectedTextColor == color ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                // Preview
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _textController.text.isEmpty
                        ? 'Preview'
                        : _textController.text,
                    style: GoogleFonts.getFont(
                      _selectedFont,
                      fontSize: _textSize,
                      color: _selectedTextColor,
                      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle:
                          _isItalic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  onTextAdded(
                    _textController.text,
                    _textSize,
                    _selectedTextColor,
                    _selectedFont,
                    _isBold,
                    _isItalic,
                  );
                  _textController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void showStickerPicker(
    BuildContext context,
    Function(String sticker) onStickerSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Sticker'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6),
            itemCount: emojiStickers.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onStickerSelected(emojiStickers[index]);
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    emojiStickers[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
