// lib/widgets/viewers/image_viewer_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:url_launcher/url_launcher.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String name;

  const ImageViewerScreen({
    Key? key,
    required this.imageUrl,
    required this.name,
  }) : super(key: key);

  Future<void> _downloadFile(BuildContext context) async {
    final uri = Uri.parse(imageUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن تحميل الملف')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (imageUrl.startsWith('http'))
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () => _downloadFile(context),
              tooltip: 'تحميل الصورة',
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
        );
      } else {
        return Image.asset(imageUrl, fit: BoxFit.contain);
      }
    } 
    else {
      if (imageUrl.startsWith('http')) {
        return Image.network(imageUrl, fit: BoxFit.contain);
      } else if (imageUrl.startsWith('assets/')) {
        return Image.asset(imageUrl, fit: BoxFit.contain);
      } else {
        return Image.file(
          File(imageUrl),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
        );
      }
    }
  }
}