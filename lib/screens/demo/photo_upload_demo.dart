import 'package:flutter/material.dart';
import '../../widgets/photo_upload_widget.dart';

class PhotoUploadDemoScreen extends StatelessWidget {
  const PhotoUploadDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Upload Demo'),
        backgroundColor: const Color(0xFFE6A43B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Pet Photo Upload',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This demo shows how to upload photos for pets. Replace "demo-pet-id" with a real pet ID from your database.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            
            PhotoUploadWidget(
              petId: 'demo-pet-id',
              onPhotosUploaded: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photos uploaded successfully! Check your pet\'s profile.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to use:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Go to "My Pets" tab and find a pet'),
                    const SizedBox(height: 8),
                    const Text('2. Get the pet ID from the pet details'),
                    const SizedBox(height: 8),
                    const Text('3. Replace "demo-pet-id" with the real pet ID'),
                    const SizedBox(height: 8),
                    const Text('4. Click "Select Photos" to upload images'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Note: The backend server must be running on http://localhost:3000 for uploads to work.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 