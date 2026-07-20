import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/theme/app_theme.dart';

class _DemoVideo {
  const _DemoVideo(this.language, this.videoId);

  final String language;
  final String videoId;
}

const _demoVideos = [
  _DemoVideo('English', '6Psv6XB6v-E'),
  _DemoVideo('اردو (Urdu)', 'MclBH4rA20s'),
  _DemoVideo('سنڌي (Sindhi)', 'vwjUY1HzKwM'),
];

/// Button shown on the login page that lets a new user watch a short
/// sign-up walkthrough video in their preferred language.
class DemoVideosButton extends StatelessWidget {
  const DemoVideosButton({super.key});

  Future<void> _openLanguagePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<_DemoVideo>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space4,
                AppTheme.space4,
                AppTheme.space4,
                AppTheme.space2,
              ),
              child: Text(
                'Watch the sign-up guide',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                  fontSize: 15,
                ),
              ),
            ),
            for (final video in _demoVideos)
              ListTile(
                leading: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppTheme.navy,
                ),
                title: Text(video.language),
                onTap: () => Navigator.of(context).pop(video),
              ),
          ],
        ),
      ),
    );

    if (selected == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DemoVideoPlayerPage(video: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _openLanguagePicker(context),
        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
        label: const Text('Signup Tutorial'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.navy,
          foregroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        ),
      ),
    );
  }
}

class _DemoVideoPlayerPage extends StatefulWidget {
  const _DemoVideoPlayerPage({required this.video});

  final _DemoVideo video;

  @override
  State<_DemoVideoPlayerPage> createState() => _DemoVideoPlayerPageState();
}

class _DemoVideoPlayerPageState extends State<_DemoVideoPlayerPage> {
  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _valueSub;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        loop: false,
      ),
    )..loadVideoById(videoId: widget.video.videoId);

    _valueSub = _controller.stream.listen((value) {
      if (value.hasError && !_hasError && mounted) {
        setState(() => _hasError = true);
      }
    });
  }

  @override
  void dispose() {
    _valueSub.cancel();
    _controller.close();
    super.dispose();
  }

  Future<void> _openInYoutube() async {
    final uri = Uri.parse(
      'https://www.youtube.com/watch?v=${widget.video.videoId}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppTheme.white,
        title: Text(widget.video.language),
      ),
      body: Center(
        child: _hasError
            ? _EmbedErrorNotice(onOpenInYoutube: _openInYoutube)
            : AspectRatio(
                aspectRatio: 9 / 16,
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 9 / 16,
                ),
              ),
      ),
    );
  }
}

class _EmbedErrorNotice extends StatelessWidget {
  const _EmbedErrorNotice({required this.onOpenInYoutube});

  final VoidCallback onOpenInYoutube;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.white,
            size: 40,
          ),
          const SizedBox(height: AppTheme.space4),
          const Text(
            "This video can't be played here.",
            style: TextStyle(color: AppTheme.white, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space4),
          OutlinedButton.icon(
            onPressed: onOpenInYoutube,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.white,
              side: const BorderSide(color: AppTheme.white),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Watch on YouTube'),
          ),
        ],
      ),
    );
  }
}
