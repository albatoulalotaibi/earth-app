import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String name;

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.name,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      String secureUrl = widget.videoUrl.trim().replaceAll(' ', '%20');
      if (secureUrl.startsWith('/')) {
        secureUrl = 'https://ruba-gsh7.onrender.com$secureUrl';
      } else if (secureUrl.startsWith('http://')) {
        secureUrl = secureUrl.replaceFirst('http://', 'https://');
      }

      final uri = Uri.parse(secureUrl);

      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(uri);
      } else {
        if (secureUrl.startsWith('http')) {
          _videoPlayerController = VideoPlayerController.networkUrl(uri);
        } else if (secureUrl.startsWith('assets/')) {
          _videoPlayerController = VideoPlayerController.asset(secureUrl);
        } else {
          _videoPlayerController = VideoPlayerController.file(File(secureUrl));
        }
      }

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blueAccent,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.white38,
        ),
        placeholder: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'تعذر تشغيل الفيديو.\n$errorMessage',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _downloadFile() async {
    if (widget.videoUrl.isEmpty) return;
    String secureUrl = widget.videoUrl.trim().replaceAll(' ', '%20');
    if (secureUrl.startsWith('/')) {
      secureUrl = 'https://ruba-gsh7.onrender.com$secureUrl';
    } else if (secureUrl.startsWith('http://')) {
      secureUrl = secureUrl.replaceFirst('http://', 'https://');
    }
    final uri = Uri.parse(secureUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن تحميل الملف')));
      }
    }
  }

  @override
  void dispose() {
    if (_chewieController != null) {
      _videoPlayerController.dispose();
      _chewieController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (widget.videoUrl.isNotEmpty && (widget.videoUrl.startsWith('http') || widget.videoUrl.startsWith('/')))
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadFile,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: _hasError
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'الرابط غير متوفر أو حدث خطأ أثناء التحميل.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : _chewieController != null &&
                      _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const CircularProgressIndicator(color: Colors.blueAccent),
        ),
      ),
    );
  }
}