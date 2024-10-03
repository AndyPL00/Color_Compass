import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class WardrobeMatchingMode extends StatefulWidget {
  final CameraController controller;

  const WardrobeMatchingMode({Key? key, required this.controller}) : super(key: key);

  @override
  _WardrobeMatchingModeState createState() => _WardrobeMatchingModeState();
}

class _WardrobeMatchingModeState extends State<WardrobeMatchingMode> {
  File? _capturedImage;
  String? _clothingType;
  bool _isCapturing = false;

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await widget.controller.takePicture();
      setState(() {
        _capturedImage = File(photo.path);
        _isCapturing = false;
      });
      _showClothingTypeSelection();
    } catch (e) {
      print('Error taking picture: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showClothingTypeSelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.access_alarm),
                title: Text('Top'),
                onTap: () => _selectClothingType('Top'),
              ),
              ListTile(
                leading: Icon(Icons.account_balance),
                title: Text('Pants'),
                onTap: () => _selectClothingType('Pants'),
              ),
              ListTile(
                leading: Icon(Icons.account_box),
                title: Text('Shoes'),
                onTap: () => _selectClothingType('Shoes'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (_clothingType == null) {
        _resetCapture();
      }
    });
  }

  Future<void> _selectClothingType(String type) async {
    setState(() {
      _clothingType = type;
    });
    Navigator.pop(context);
    await _saveImage();
    _resetCapture();
  }

  Future<void> _saveImage() async {
    if (_capturedImage == null || _clothingType == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_clothingType.jpg';
    final savedImage = await _capturedImage!.copy(path.join(directory.path, fileName));

    // Here you would typically save the image path and clothing type to a local database
    print('Image saved: ${savedImage.path}');
    print('Clothing type: $_clothingType');
  }

  void _resetCapture() {
    setState(() {
      _capturedImage = null;
      _clothingType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_capturedImage != null)
          Image.file(_capturedImage!, fit: BoxFit.cover),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 120.0), // Adjusted to account for ModeSelector
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_capturedImage != null)
                  FloatingActionButton(
                    onPressed: _resetCapture,
                    child: Icon(Icons.cancel),
                    backgroundColor: Colors.red,
                  ),
                FloatingActionButton(
                  onPressed: _capturedImage == null ? _takePicture : null,
                  child: Icon(Icons.camera),
                  backgroundColor: _capturedImage == null ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}