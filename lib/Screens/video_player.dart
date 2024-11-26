import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_api/youtube_api.dart';

class Video extends StatefulWidget {
  final String id;
  final YT_API data;
  const Video({super.key, required this.id, required this.data});

  @override
  State<Video> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  @override
  Widget build(BuildContext context) {
    var videoId = YoutubePlayer.convertUrlToId(widget.id);
    // YoutubeDownloader youtubeDownloader = YoutubeDownloader();
    YoutubePlayerController _controller = YoutubePlayerController(
      initialVideoId: '$videoId',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    return Scaffold(
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.amber,
          onReady: () {
            _controller.play();
          },
        ),
      ),
    );
  }
}
