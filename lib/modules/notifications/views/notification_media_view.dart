import 'package:flutter/material.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:video_player/video_player.dart';

class NotificationMediaView extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? videoUrl;

  const NotificationMediaView({
    super.key,
    required this.title,
    this.imageUrl,
    this.videoUrl,
  });

  @override
  State<NotificationMediaView> createState() => _NotificationMediaViewState();
}

class _NotificationMediaViewState extends State<NotificationMediaView>
    with WidgetsBindingObserver {
  VideoPlayerController? _video;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.videoUrl != null) _loadVideo();
  }

  Future<void> _loadVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl!),
    );
    _video = controller;
    controller.addListener(_refresh);
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.play();
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to play video');
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _video?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.removeListener(_refresh);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final failed = _error != null || (video?.value.hasError ?? false);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: widget.videoUrl == null
            ? Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(child: _MediaLoader()),
                    errorBuilder: (_, error, stack) => const Text(
                      'Image unavailable',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              )
            : failed
            ? const Center(
                child: Text(
                  'Unable to play video',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : video == null || !video.value.isInitialized
            ? const Center(child: _MediaLoader())
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: video.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(video),
                            if (video.value.isBuffering)
                              const IgnorePointer(child: _MediaLoader()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  VideoProgressIndicator(
                    video,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.primaryColor,
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white12,
                    ),
                    padding: const EdgeInsets.all(16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        color: Colors.white,
                        tooltip: video.value.isPlaying ? 'Pause' : 'Play',
                        icon: Icon(
                          video.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () async {
                          if (video.value.isPlaying) {
                            await video.pause();
                          } else {
                            if (video.value.position >= video.value.duration) {
                              await video.seekTo(Duration.zero);
                            }
                            await video.play();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _MediaLoader extends StatelessWidget {
  const _MediaLoader();

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.65),
      shape: BoxShape.circle,
    ),
    child: const CircularProgressIndicator(
      strokeWidth: 2,
      color: AppColors.primaryColor,
      backgroundColor: Colors.white12,
      semanticsLabel: 'Loading media',
    ),
  );
}
