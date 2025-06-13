import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ImageService {
  static const String baseUrl = ApiService.baseUrl;
  final ImagePicker _picker = ImagePicker();

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  Future<List<XFile>?> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (images.length > maxImages) {
        return images.take(maxImages).toList();
      }
      
      return images;
    } catch (e) {
      print('Error picking multiple images: $e');
      return null;
    }
  }

  Future<String?> uploadUserAvatar(XFile imageFile) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/users/profile/avatar');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      
      final file = File(imageFile.path);
      final multipartFile = await http.MultipartFile.fromPath(
        'avatar',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = parseJsonResponse(responseData);
        return jsonResponse['avatarUrl'];
      } else {
        throw Exception('Failed to upload avatar: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  Future<List<String>?> uploadPetPhotos(String petId, List<XFile> imageFiles) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/pets/$petId/photos');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      
      for (final imageFile in imageFiles) {
        final file = File(imageFile.path);
        final multipartFile = await http.MultipartFile.fromPath(
          'photos',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = parseJsonResponse(responseData);
        final imageUrls = List<String>.from(jsonResponse['imageUrls']);
        print('ImageService - Pet photos uploaded: $imageUrls');
        return imageUrls;
      } else {
        throw Exception('Failed to upload photos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading pet photos: $e');
      return null;
    }
  }

  Map<String, dynamic> parseJsonResponse(String responseData) {
    try {
      return jsonDecode(responseData);
    } catch (e) {
      throw Exception('Failed to parse response: $e');
    }
  }

  Future<ImageSource?> showImageSourceDialog() async {
    return ImageSource.gallery;
  }
} 