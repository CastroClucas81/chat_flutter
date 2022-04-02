import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  final Function({String text, File imgFile}) sendMessage;

  TextComposer({
    Key? key,
    required this.sendMessage,
  }) : super(key: key);

  @override
  State<TextComposer> createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;
  final ImagePicker _picker = ImagePicker();

  void _reset() {
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              XFile? photo;

              photo = await _picker.pickImage(source: ImageSource.camera);

              if (photo == null) return;
              widget.sendMessage(imgFile: File(photo.path));
            },
            icon: Icon(
              Icons.photo_camera,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: (text) {
                widget.sendMessage(text: _controller.text);
                _reset();
              },
              decoration:
                  InputDecoration.collapsed(hintText: "Enviar uma mensage..."),
            ),
          ),
          IconButton(
            onPressed: _isComposing
                ? () {
                    widget.sendMessage(text: _controller.text);
                    _reset();
                  }
                : null,
            icon: Icon(Icons.send),
          )
        ],
      ),
    );
  }
}
