import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// A service to handle uploading media (images and videos) to Cloudinary.
class CloudinaryService {
  // TODO: Replace with your actual Cloudinary cloud name.
  static const String _cloudName = 'djlajdefb';
  // TODO: Replace with your actual unsigned upload preset name.
  static const String _uploadPreset = 'civiclens_uploads';

  /// Uploads an image file to Cloudinary.
  /// 
  /// Returns the [secure_url] if successful, or `null` if the upload fails.
  Future<String?> uploadImage(File file) async {
    return _uploadMedia(file, resourceType: 'image');
  }

  /// Uploads a video file to Cloudinary.
  /// 
  /// Returns the [secure_url] if successful, or `null` if the upload fails.
  Future<String?> uploadVideo(File file) async {
    return _uploadMedia(file, resourceType: 'video');
  }

  /// Generic private method to handle uploading files to Cloudinary via HTTP POST.
  Future<String?> _uploadMedia(File file, {required String resourceType}) async {
    try {
      // The Cloudinary upload API endpoint.
      final Uri uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );

      final http.MultipartRequest request = http.MultipartRequest('POST', uri);

      // Add the unsigned upload preset
      request.fields['upload_preset'] = _uploadPreset;

      // Attach the file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      // Send the request
      final http.StreamedResponse response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);

        // Return the secure URL provided by Cloudinary
        return jsonResponse['secure_url'] as String?;
      } else {
        final String errorBody = await response.stream.bytesToString();
        print('Cloudinary upload failed: [${response.statusCode}] $errorBody');
        return null;
      }
    } catch (e) {
      print('An error occurred during Cloudinary upload: $e');
      return null;
    }
  }
}
