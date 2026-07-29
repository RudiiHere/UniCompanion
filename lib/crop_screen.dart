// lib/screens/profile/crop_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import '../../config/app_theme.dart';

/// Full-screen avatar cropper. Pass the original image bytes; it returns the
/// cropped square bytes via Navigator.pop (or null if cancelled).
/// Pure Dart — no native cropper, so it always returns the actual crop.
class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const AvatarCropScreen({super.key, required this.imageBytes});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _controller = CropController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Adjust photo'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                setState(() => _busy = true);
                // cropCircle() outputs a real circle-shaped image (transparent
                // corners), so the saved avatar IS a circle — not a square that
                // merely looks round inside a circular frame.
                _controller.cropCircle();
              },
              child: const Text('Done',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              aspectRatio: 1,          // square — fits the circular avatar
              withCircleUi: true,      // show a circular crop guide
              interactive: true,       // let the user pinch-zoom & drag
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.6),
              onCropped: (result) {
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    if (mounted) Navigator.of(context).pop(croppedImage);
                  case CropFailure():
                    if (mounted) {
                      setState(() => _busy = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not crop the image. Please try again.')),
                      );
                    }
                }
              },
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pinch_rounded, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text('Pinch to zoom, drag to position',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}