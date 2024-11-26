import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Screens/play.dart';
import 'package:zylae/Screens/playlist.dart';
import 'package:zylae/Screens/showCase.dart';

import '../Services/classes.dart';
import '../Widgets/songTile.dart';
import '../apis/api.dart';
import 'album.dart';

class Artist extends StatefulWidget {
  final String token;
  final String id;
  final String name;
  final String asset;
  final AudioPlayer player;
  final KStates state;
  const Artist({super.key, required this.token, required this.id, required this.name, required this.asset, required this.player, required this.state});

  @override
  State<Artist> createState() => _ArtistState();
}

class _ArtistState extends State<Artist> {
  bool loading = true;
  bool fetched = false;
  List recon = [];

  Map<String, List<dynamic>> songList = {};
  Future<void> _fetchSongs() async {
    recon.clear();
    songList.clear();
    setState(() {
      loading = true;
      fetched = false;
    });
    try {
      songList = await SaavnAPI().fetchArtistSongs(artistToken: widget.token);
    } catch (e) {
      print(e);
    }
    setState(() {
      loading = false;
      fetched = true;
    });
    print(songList.length);
    recon = songList.keys.toList();
    print(songList.keys);
    // print(songList.valuesList()[0][0]['name']);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchSongs();
  }

  Map iconB = {'artist': Icons.person, 'playlist': Icons.playlist_play_rounded, 'song': Icons.music_note, 'album': Icons.album};
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

  @override
  Widget build(BuildContext context) {
    // print(songList);
    // print(songList['Top Songs']);
    // print(songList[recon[0]]);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color.fromARGB(0, 9, 2, 41),
      ),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 9, 2, 41),
        floatingActionButton: widget.state.isLoaded
            ? FloatingActionButton.extended(
                backgroundColor: Colors.transparent,
                onPressed: () {},
                label: Container(
                  height: 120,
                  width: context.screenWidth,
                  child: StreamBuilder(
                      stream: widget.player.positionStream,
                      builder: (context, snapshot1) {
                        // getOnlineInfo(playing);

                        final Duration duration = widget.state.isLoaded ? widget.player.position : const Duration(seconds: 0);
                        return InkWell(
                          onTap: () async {
                            await VxBottomSheet.bottomSheetView(context,
                                child: Play(
                                  player: widget.player,
                                  isOnline: "${widget.state.tags[widget.player.sequenceState!.currentIndex]['url']}".contains('http'),
                                  onLinePlaylist: false,
                                  onlineSongData: [],
                                  play: false,
                                  shuffle: false,
                                  state: widget.state,
                                  index: widget.player.sequenceState!.currentIndex,
                                ),
                                maxHeight: 1,
                                minHeight: 1);
                          },
                          child: Container(
                            height: 62,
                            width: context.percentWidth,
                            decoration: BoxDecoration(color: const Color.fromARGB(255, 45, 8, 96), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                widget.state.tags.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: widget.state.isLoaded
                                            ? widget.state.tags[widget.player.sequenceState!.currentIndex]['image'].runtimeType != String
                                                ? Image.memory(
                                                    widget.state.tags[widget.player.sequenceState!.currentIndex]['image'],
                                                    height: 60,
                                                    width: 60,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    widget.state.tags[widget.player.sequenceState!.currentIndex]['image'],
                                                    height: 60,
                                                    width: 60,
                                                    fit: BoxFit.cover,
                                                  )
                                            : Image.asset(
                                                'assets/tune.png',
                                                height: 60,
                                                width: 60,
                                                fit: BoxFit.cover,
                                              ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.asset(
                                          'assets/tune.png',
                                          height: 60,
                                          width: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    widget.state.isLoaded
                                        ? Text(
                                            widget.state.tags[widget.player.sequenceState!.currentIndex]['title'],
                                            maxLines: 2,
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                          )
                                        : const Text(
                                            "Nothing playing",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                    widget.state.isLoaded
                                        ? Text(
                                            widget.state.tags[widget.player.sequenceState!.currentIndex]['artist'],
                                            maxLines: 1,
                                          )
                                        : ''.text.make(),
                                  ],
                                ).px8().py2().box.width(context.screenWidth * 0.44).make(),
                                const Spacer(),
                                Row(
                                  children: [
                                    widget.state.isLoaded
                                        ? IconButton(
                                            onPressed: () {
                                              if (widget.player.playing) {
                                                setState(() {
                                                  widget.player.pause();
                                                });
                                              } else {
                                                setState(() {
                                                  widget.player.play();
                                                });
                                              }
                                            },
                                            icon: Icon(
                                              widget.player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                              size: 30,
                                              color: Colors.white,
                                            ))
                                        : IconButton(onPressed: () {}, icon: Icon(Icons.replay)),
                                    widget.state.isLoaded
                                        ? IconButton(
                                            onPressed: () async {
                                              widget.player.hasNext ? await widget.player.seekToNext() : null;
                                              widget.player.play();

                                              setState(() {});
                                            },
                                            icon: Icon(
                                              Icons.fast_forward_rounded,
                                              color: widget.player.hasNext ? Colors.white : Colors.grey.shade600,
                                              size: 20,
                                            ))
                                        : "".text.make(),
                                  ],
                                )
                              ],
                            ).py4().px2(),
                          ),
                        );
                      }).box.width(context.screenWidth * 0.9).makeCentered(),
                ),
              )
            : Row(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: loading
            ? CircularProgressIndicator().centered()
            : LiquidPullToRefresh(
                onRefresh: _fetchSongs,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar.large(
                      pinned: false,
                      expandedHeight: context.screenHeight * 0.55,
                      backgroundColor: const Color.fromARGB(255, 9, 2, 41),
                      bottom: PreferredSize(
                          preferredSize: Size.fromHeight(context.screenHeight * 0.04),
                          child: SizedBox(
                            child: widget.name.text.center.scale(2).semiBold.make().py20().px16().box.width(context.screenWidth).make(),
                          )),
                      title: Text(widget.name),
                      flexibleSpace: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          InkWell(
                            onTap: () {
                              try {
                                print(songList);
                              } catch (e) {
                                print(e);
                              }
                            },
                            child: CachedNetworkImage(
                              imageUrl: widget.asset,
                              key: Key(widget.asset),
                              cacheKey: widget.asset,
                              fit: BoxFit.cover,
                            ).box.width(context.screenWidth).make(),
                          ),
                        ],
                      ),
                    ),
                    SliverList.builder(
                        itemCount: songList.length,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            height: context.screenHeight * 0.3,
                            width: context.screenWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // trailing: Icon(iconB[songList[recon[index]]?[0]?['type']]),
                              // initiallyExpanded: true,
                              // maintainState: true,
                              // title: ,
                              // leading: songList[recon[index]]!.length.toString().text.make(),
                              // children: List.generate(
                              //   songList[recon[index]]!.length >= 7 ? 7 : songList[recon[index]]!.length,
                              //   (indexx)
                              //   // SongTile(
                              //   //   trailing: false,
                              //   //   data: songList[recon[index]]?[indexx],
                              //   //   index: index,
                              //   //   player: widget.player,
                              //   //   state: widget.state,
                              //   // ),
                              //   {
                              // ),
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      recon[index],
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(context, CupertinoPageRoute(builder: (context) => ShowCase(name: recon[index], items: songList[recon[index]] ?? [], state: widget.state, player: widget.player)));
                                      },
                                      child: Row(
                                        children: ["View all".text.scale(.91).make().px16(), Icon(FeatherIcons.arrowRight)],
                                      ),
                                    ),
                                  ],
                                ).px8(),
                                SizedBox(
                                  height: context.screenHeight * 0.2,
                                  width: context.screenWidth,
                                  child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: songList[recon[index]]!.length >= 7 ? 7 : songList[recon[index]]!.length,
                                      itemBuilder: (context, i) {
                                        try {
                                          return songList[recon[index]]?[i]['type'] != 'song'
                                              ? InkWell(
                                                  onTap: () {
                                                    if (songList[recon[index]]?[i]['type'] == 'album') {
                                                      _album(
                                                        songList[recon[index]]?[i]['id'],
                                                        songList[recon[index]]?[i]['title'],
                                                        songList[recon[index]]?[i]['image'],
                                                        '',
                                                        widget.state,
                                                      );
                                                    } else if (songList[recon[index]]?[i]['type'] == 'playlist') {
                                                      _playlist(
                                                        songList[recon[index]]?[i]['id'],
                                                        songList[recon[index]]?[i]['image'],
                                                        songList[recon[index]]?[i]['title'],
                                                        widget.state,
                                                      );
                                                    } else if (songList[recon[index]]?[i]['type'] == 'artist') {
                                                      _artist(
                                                        songList[recon[index]]?[i]['id'],
                                                        songList[recon[index]]?[i]['artistToken'],
                                                        songList[recon[index]]?[i]['title'],
                                                        songList[recon[index]]?[i]['image'],
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
                                                            imageUrl: songList[recon[index]]?[i]['image'],
                                                            key: Key(songList[recon[index]]?[i]['image']),
                                                            cacheKey: songList[recon[index]]?[i]['image'],
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
                                                            songList[recon[index]]?[i]['title'],
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
                                                )
                                              : InkWell(
                                                  onTap: () async {
                                                    widget.state.setLists([songList[recon[index]]?[i]], []);
                                                    await VxBottomSheet.bottomSheetView(context,
                                                        child: Play(
                                                          player: widget.player,
                                                          isOnline: true,
                                                          shuffle: false,
                                                          onLinePlaylist: false,
                                                          onlineSongData: [songList[recon[index]]?[i]],
                                                          play: true,
                                                          state: widget.state,
                                                          index: 0,
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
                                                          // child: Text(songList[recon[index]]?[i]['title']),
                                                          decoration: BoxDecoration(
                                                            color: Colors.deepPurple.shade800,
                                                            shape: BoxShape.circle,
                                                            image: DecorationImage(
                                                              image: NetworkImage(
                                                                songList[recon[index]]?[i]['image'],
                                                              ),
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            Icons.play_arrow_rounded,
                                                            size: 65,
                                                            color: Colors.white.withOpacity(.75),
                                                          ),
                                                        ),
                                                        Text(
                                                          songList[recon[index]]?[i]['title'],
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          maxLines: 1,
                                                          textAlign: TextAlign.center,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                );
                                        } catch (e) {
                                          print(e);
                                        }
                                        return null;
                                        // return data[list[index]][i]?['title'] ? Text("Null") : Text(data[list[index]][i]?['title']);
                                        // return Image.network(data[list[index]][i]['image'], width: context.screenWidth * 0.3, height: context.screenHeight * 0.09);
                                      }),
                                ),
                              ],
                            ).box.height(context.screenHeight * 0.2).width(context.screenWidth).make(),
                          );
                        }),
                  ],
                ),
              ),
      ),
    );
  }
}
