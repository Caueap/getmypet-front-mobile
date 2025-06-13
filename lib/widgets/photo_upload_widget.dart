import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';

class PhotoUploadWidget extends StatefulWidget {
  final String petId;
  final VoidCallback? onPhotosUploaded;

  const PhotoUploadWidget({
    super.key,
    required this.petId,
    this.onPhotosUploaded,
  });

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final ImageService _imageService = ImageService();
  bool _isUploading = false;

  Future<void> _uploadPhotos() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final List<XFile>? imageFiles = await _imageService.pickMultipleImages(maxImages: 5);
      
      if (imageFiles == null || imageFiles.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final List<String>? uploadedUrls = await _imageService.uploadPetPhotos(
        widget.petId,
        imageFiles,
      );

      setState(() {
        _isUploading = false;
      });

      if (uploadedUrls != null && uploadedUrls.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadedUrls.length} photos uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onPhotosUploaded?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload photos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload up to 5 photos to showcase your pet better',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadPhotos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6A43B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add_a_photo),
                label: Text(_isUploading ? 'Uploading...' : 'Select Photos'),
              ),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
} 