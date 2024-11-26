import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Screens/play.dart';
import 'package:zylae/Screens/playlist.dart';

import '../Services/classes.dart';
import '../Widgets/songTile.dart';
import '../Widgets/song_circle.dart';
import 'album.dart';
import 'artist.dart';

class ShowCase extends StatefulWidget {
  final String name;
  final List items;
  final KStates state;
  final AudioPlayer player;
  const ShowCase({super.key, required this.name, required this.items, required this.state, required this.player});

  @override
  State<ShowCase> createState() => _ShowCaseState();
}

class _ShowCaseState extends State<ShowCase> {
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

  List songLinks = [];
  @override
  Widget build(BuildContext context) {
    for (int i = 0; songLinks.length < widget.items.length; i++) {
      songLinks.add(widget.items[i]['url']);
    }
    return Scaffold(
      appBar: AppBar(
        title: widget.name.text.make(),
      ),
      body: CustomScrollView(
        slivers: [
          widget.items[0]['type'] != 'song'
              ? SliverGrid.builder(
                  itemCount: widget.items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                  itemBuilder: ((context, index) {
                    return InkWell(
                      onTap: () {
                        if (widget.items[index]['type'] == 'album') {
                          _album(
                            widget.items[index]['id'],
                            widget.items[index]['title'],
                            widget.items[index]['image'],
                            '',
                            widget.state,
                          );
                        } else if (widget.items[index]['type'] == 'playlist') {
                          _playlist(
                            widget.items[index]['id'],
                            widget.items[index]['image'],
                            widget.items[index]['title'],
                            widget.state,
                          );
                        } else if (widget.items[index]['type'] == 'artist') {
                          _artist(
                            widget.items[index]['id'],
                            widget.items[index]['artistToken'],
                            widget.items[index]['title'],
                            widget.items[index]['image'],
                            widget.state,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        width: context.screenWidth * 0.35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.deepPurple,
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: CachedNetworkImage(
                                imageUrl: widget.items[index]['image'],
                                key: Key(widget.items[index]['image']),
                                cacheKey: widget.items[index]['image'],
                                // loadingBuilder: (context, child, loadingProgress) {
                                //   return const CircularProgressIndicator(
                                //           // value: (loadingProgress!.cumulativeBytesLoaded.toDouble() / loadingProgress.expectedTotalBytes!.toDouble()),
                                //           )
                                //       .centered();
                                // },
                                fit: BoxFit.cover,
                                errorWidget: (context, error, stackTrace) {
                                  return const Icon(EvaIcons.image).centered();
                                },
                              ).box.height(double.maxFinite).width(double.maxFinite).make(),
                            ),
                            Container(
                              height: double.maxFinite,
                              width: double.maxFinite,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.black,
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              alignment: Alignment.bottomLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                              child: Text(
                                widget.items[index]['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 2,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [IconButton(onPressed: () {}, icon: const Icon(EvaIcons.moreHorizontalOutline))],
                            ),
                          ],
                        ),
                      ),
                    );
                  }))
              : SliverList.builder(itemBuilder: (context, index) {
                  return SongTile(
                    data: widget.items[index],
                    trailing: false,
                    index: index,
                    player: widget.player,
                    state: widget.state,
                    items: widget.items,
                  );
                })
        ],
      ),
    );
  }
}
