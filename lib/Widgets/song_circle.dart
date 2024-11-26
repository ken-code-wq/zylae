import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:velocity_x/velocity_x.dart';

import '../Screens/play.dart';
import '../Services/classes.dart';
import '../Services/download.dart';

class SongCircle extends StatefulWidget {
  final Map item;
  final KStates state;
  final AudioPlayer player;
  final List songLinks;
  final int index;
  const SongCircle({super.key, required this.item, required this.state, required this.player, required this.songLinks, required this.index});

  @override
  State<SongCircle> createState() => _SongCircleState();
}

class _SongCircleState extends State<SongCircle> {
  late Download down;
  @override
  void initState() {
    super.initState();
    down = Download(widget.item['id'].toString());
    down.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  void _download(var data) async {
    try {
      down.prepareDownload(context, data);
      await _waitUntilDone(widget.item['id']);
      setState(() {
        finished = true;
        // downloading = false;
      });
    } catch (e) {
      // print(e);
    }
  }

  bool finished = false;
  bool downloading = false;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        VxBottomSheet.bottomSheetView(
          context,
          child: Container(
            height: 150,
            width: context.screenWidth,
            child: ListTile(
              title: Text("Download"),
              leading: Icon(FeatherIcons.downloadCloud),
              onTap: () {
                setState(() {
                  downloading = true;
                });
                _download(widget.item);
              },
              trailing: downloading
                  ? CircularProgressIndicator(
                      value: down.progress,
                    )
                  : !finished
                      ? ''.text.make()
                      : Icon(Icons.download_done),
            ).py24().px12(),
          ),
        );
      },
      onTap: () async {
        widget.state.setLists(widget.songLinks, []);
        await VxBottomSheet.bottomSheetView(context,
            child: Play(
              player: widget.player,
              isOnline: true,
              shuffle: false,
              onLinePlaylist: true,
              onlineSongData: [widget.songLinks],
              play: true,
              state: widget.state,
              index: widget.index,
            ),
            maxHeight: 1,
            minHeight: 1);
        widget.state.loadState(true);
      },
      child: Container(
        width: context.screenWidth * 0.35,
        // color: Colors.amber,
        margin: EdgeInsets.only(left: 12),
        alignment: Alignment.topCenter,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              width: context.screenWidth * 0.3,
              // child: Text( widget.items[index]['title']),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade800,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                    widget.item['image'],
                  ),
                ),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 65,
                color: Colors.white.withOpacity(.75),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.item['title'],
                  style: const TextStyle(fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis, fontSize: 17),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.item['artist'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
