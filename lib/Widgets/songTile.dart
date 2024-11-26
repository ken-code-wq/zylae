import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Screens/album.dart';
import 'package:retry/retry.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:zylae/Screens/artist.dart';

import '../Helpers/lyrics.dart';
import '../Screens/play.dart';
import '../Screens/playlist.dart';
import '../Services/classes.dart';
import '../Services/download.dart';

class SongTile extends StatefulWidget {
  final Map data;
  final List items;
  final int index;
  final bool trailing;
  final AudioPlayer player;
  final KStates state;
  const SongTile({super.key, required this.data, required this.trailing, required this.index, required this.player, required this.state, required this.items});

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  String preferredDownloadQuality = '320 kbps';
  late Download down;
  @override
  void initState() {
    super.initState();
    down = Download(widget.data['id'].toString());
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
    var box = generalBox.getAt(1);
    print(box);
    try {
      down.prepareDownload(context, data);
      generalBox.putAt(1, box);
      await _waitUntilDone(widget.data['id']);
      setState(() {
        finished = true;
        // downloading = false;
      });
      box.add(widget.data['id']);
    } catch (e) {
      // print(e);
    }
  }

  // void _playMusic(var data) async {
  //   String kUrl = widget.data['url'];
  //   kUrl = kUrl.replaceAll(
  //     '_96.',
  //     "_${preferredDownloadQuality.replaceAll(' kbps', '')}.",
  //   );
  //   final audioPlayer = AudioPlayer();
  //   await audioPlayer.play(AssetSource('C:/Users/User/Downloads/${widget.data['name']}'));
  // }

  void _album(String id, String name, String asset, String artist, KStates state) {
    // Provider.of<KStates>(context, listen: false).setData(id: id, album: name, image: asset, artistName: artist, token: '', name: name, type: 'album', url: '');

    // Provider.of<KStates>(context, listen: false).setCP(4);

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => Album(
          id: id,
          name: name,
          asset: asset,
          artist: artist,
          player: widget.player,
          state: state,
        ),
      ),
    );
  }

  void _artist(String id, String token, String name, String asset, KStates state) {
    // Provider.of<KStates>(context, listen: false).setData(id: id, album: '', image: asset, artistName: name, token: token, name: name, type: 'artist', url: '');
    // Provider.of<KStates>(context, listen: false).setCP(5);

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => Artist(
          id: id,
          token: token,
          asset: asset,
          name: name,
          player: widget.player,
          state: state,
        ),
      ),
    );
  }

  void _playlist(String id, String asset, String name, KStates state) {
    // Provider.of<KStates>(context, listen: false).setData(id: id, album: '', image: asset, artistName: '', token: '', name: name, type: 'playlist', url: '');
    // Provider.of<KStates>(context, listen: false).setCP(6);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PlayList(
          id: id,
          asset: asset,
          name: name,
          player: widget.player,
          state: state,
        ),
      ),
    );
  }

  var generalBox = Hive.box('general');

  bool finished = false;
  bool downloading = false;
  Map iconB = {'artist': Icons.person, 'playlist': Icons.playlist_play_rounded, 'song': Icons.music_note, 'album': Icons.album};

  @override
  Widget build(BuildContext context) {
    List box = generalBox.getAt(1);
    return InkWell(
      onTap: () async {
        print(widget.items);
        if (widget.data['type'] == 'song') {
          widget.state.setLists(widget.items, [widget.data['image']]);
          // ignore: use_build_context_synchronously
          await VxBottomSheet.bottomSheetView(context,
              child: Play(
                player: widget.player,
                isOnline: true,
                onLinePlaylist: false,
                shuffle: false,
                onlineSongData: [widget.data['url']],
                play: true,
                state: widget.state,
                index: widget.index,
              ),
              maxHeight: 1,
              minHeight: 1);

          widget.state.loadState(true);

          // Provider.of<KStates>(context, listen: false).changePS(true);
          // Provider.of<KStates>(context, listen: false).setApiData(widget.data);
          // Provider.of<KStates>(context, listen: false).open(
          //   SongData(
          //       title: widget.data['title'],
          //       artist: widget.data['artist'],
          //       album: widget.data['album'],
          //       genre: widget.data['genre'],
          //       year: int.parse(widget.data['year']),
          //       duration: int.parse(widget.data['duration']),
          //       picture: widget.data['image'],
          //       id: widget.data['id'],
          //       type: Type.song,
          //       url: widget.data['url']),
          // );
        } else if (widget.data['type'] == 'album') {
          _album(widget.data['id'], widget.data['album'], widget.data['image'], widget.data['artist'], widget.state);
        } else if (widget.data['type'] == 'playlist') {
          _playlist(widget.data['id'], widget.data['image'], widget.data['album'], widget.state);
        } else if (widget.data['type'] == 'artist') {
          _artist(widget.data['id'], widget.data['artistToken'], widget.data['title'], widget.data['image'], widget.state);
        }
      },
      child: ListTile(
        // isThreeLine: true,
        subtitle: widget.data['type'] != 'song'
            ? Text("${widget.data['artist']}")
            : Text(
                "${widget.data['artist']} - ${Duration(seconds: int.parse(widget.data['duration'])).inMinutes}:${(Duration(seconds: int.parse(widget.data['duration'])).inSeconds - (60 * Duration(seconds: int.parse(widget.data['duration'])).inMinutes)) > 9 ? Duration(seconds: int.parse(widget.data['duration'])).inSeconds - (60 * Duration(seconds: int.parse(widget.data['duration'])).inMinutes) : "0${Duration(seconds: int.parse(widget.data['duration'])).inSeconds - (60 * Duration(seconds: int.parse(widget.data['duration'])).inMinutes)}"}"),
        leading: !widget.trailing
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  widget.data['image'],
                  errorBuilder: (context, error, stackTrace) => const Text("X"),
                  height: context.screenWidth * 0.15,
                  width: context.screenWidth * 0.15,
                ),
              )
            : (widget.index + 1).toString().text.semiBold.make(),
        // dense: true,
        title: Text(
          widget.data['title'],
          overflow: TextOverflow.fade,
        ),
        // trailing: widget.data['type'] == 'song'
        //     ? box.contains(widget.data['id'])
        //         ? IconButton(
        //             onPressed: () async {
        //               widget.state.setLists([widget.data], [widget.data['image']]);
        //               await VxBottomSheet.bottomSheetView(context,
        //                   child: Play(
        //                     player: widget.player,
        //                     isOnline: false,
        //                     onLinePlaylist: false,
        //                     shuffle: false,
        //                     onlineSongData: ["/storage/emulated/0/Android/data/com.zylae/files/downloads/${widget.data['title']}"],
        //                     play: true,
        //                     state: widget.state,
        //                     index: 0,
        //                   ),
        //                   maxHeight: 1,
        //                   minHeight: 1);
        //               widget.state.loadState(true);
        //             },
        //             icon: const Icon(FeatherIcons.play))
        //         : !downloading
        //             ? IconButton(
        //                 icon: const Icon(FeatherIcons.downloadCloud),
        //                 onPressed: () {
        //                   setState(() {
        //                     downloading = true;
        //                   });
        //                   _download(widget.data);
        //                 },
        //               )
        //             : CircularProgressIndicator(
        //                 value: down.progress,
        //               )
        //     : null,
        trailing: downloading == finished
            ? PullDownButton(
                itemBuilder: (context) => [
                  const PullDownMenuHeader(leading: Icon(FeatherIcons.activity), title: "Activity"),
                  PullDownMenuItem(
                    title: "Play",
                    onTap: () async {
                      if (widget.data['type'] == 'song') {
                        print(widget.data['url']);
                        widget.state.setLists([widget.data], [widget.data['image']]);
                        await VxBottomSheet.bottomSheetView(context,
                            child: Play(
                              player: widget.player,
                              isOnline: true,
                              onLinePlaylist: false,
                              shuffle: false,
                              onlineSongData: [widget.data['url']],
                              play: true,
                              state: widget.state,
                              index: widget.index,
                            ),
                            maxHeight: 1,
                            minHeight: 1);

                        widget.state.loadState(true);
                      }
                    },
                    icon: FeatherIcons.play,
                  ),
                  // ignore: deprecated_member_use
                  // const PullDownMenuDivider(),
                  PullDownMenuItem(
                    title: 'Download',
                    onTap: () async {
                      setState(() {
                        downloading = true;
                      });
                      _download(widget.data);
                      widget.state.setLoadState(widget.state.loadHome, true);
                      SongModel song = SongModel({
                        "_id": widget.data['id'],
                        '_data': widget.data,
                        '_uri': widget.data['url'],
                        '_display_name': "${widget.data['title']}.m4a",
                        '_dispay_name_wo_ext': widget.data['title'],
                        'album': widget.data['album'],
                        'artist': widget.data['artist'],
                        'title': widget.data['title'],
                        'is_music': true,
                      });
                    },
                    icon: FeatherIcons.downloadCloud,
                  ),
                ],
                buttonBuilder: (context, showMenu) => CupertinoButton(
                  onPressed: showMenu,
                  padding: EdgeInsets.zero,
                  child: const Icon(FeatherIcons.moreVertical),
                ),
              )
            : CircularProgressIndicator(
                value: down.progress,
              ),
      ),
    );
  }
}
