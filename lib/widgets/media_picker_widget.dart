import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerWidget extends StatefulWidget {
  final Function(File? file, String? type) onMediaSelected;

  const MediaPickerWidget({super.key, required this.onMediaSelected});

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String? _mediaType; // 'image' or 'video'

  Future<void> _pickMedia(bool isVideo, ImageSource source) async {
    try {
      final XFile? pickedFile = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _mediaType = isVideo ? 'video' : 'image';
        });
        widget.onMediaSelected(_selectedFile, _mediaType);
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick media. Please try again.')),
        );
      }
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedFile = null;
      _mediaType = null;
    });
    widget.onMediaSelected(null, null);
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(false, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Photo from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(false, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record a Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(true, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Choose Video from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(true, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedFile != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.hardEdge,
            child: _mediaType == 'image'
                ? Image.file(
                    _selectedFile!,
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_file, size: 50, color: Colors.blueGrey),
                        SizedBox(height: 8),
                        Text('Video Selected', style: TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: _removeMedia,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white70,
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => _showPickerOptions(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.shade200,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 40, color: Colors.blue.shade400),
            const SizedBox(height: 8),
            Text(
              'Add Photo / Video',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
