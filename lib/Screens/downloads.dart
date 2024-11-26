import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Screens/play.dart';

import '../Services/QueryServices.dart';
import '../Services/classes.dart';
import '../Services/customRoute.dart';

class Downloads extends StatefulWidget {
  final AudioPlayer player;
  final KStates state;
  const Downloads({super.key, required this.player, required this.state});

  @override
  State<Downloads> createState() => _DownloadsState();
}

List<SongModel> songs = [];

class _DownloadsState extends State<Downloads> {
  void getSongs() async {
    print("OKay");
    songs = await widget.state.audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
      path: '/storage/emulated/0/Kylae',
    );
    print("Done $songs");
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSongs();
  }

  @override
  Widget build(BuildContext context) {
    Playlists? fav = Hive.box<Playlists>('playList').get('favs');
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 10, 10, 10),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Play(
                                player: widget.player,
                                isOnline: "${widget.state.tags[widget.player.sequenceState!.currentIndex]['url']}".contains('http'),
                                onLinePlaylist: false,
                                onlineSongData: [],
                                play: false,
                                shuffle: false,
                                state: widget.state,
                                index: widget.player.sequenceState!.currentIndex,
                              ),
                            ),
                          );
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
      body: songs.isNotEmpty
          ? ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == songs.length - 1 ? 120 : 0),
                  child: ListTile(
                    trailing: Container(
                      height: 56,
                      width: 92,
                      child: Row(
                        children: [
                          IconButton(
                              onPressed: () async {
                                if (fav.songs.indexWhere((element) => element.title == songs[index].title) != -1) {
                                  print("removing");
                                  await PlaylistServices().removeFromPlaylist(
                                    'favs',
                                    fav.songs.indexWhere((element) {
                                      return element.title == songs[index].title;
                                    }),
                                  );
                                  setState(() {});
                                } else {
                                  print("adding");
                                  String file = songs[index].data;
                                  final tagger = Audiotagger();
                                  var songData = await tagger.readTagsAsMap(path: file);
                                  final metaData = await MetadataRetriever.fromFile(File(file));
                                  var albumArt = metaData.albumArt;
                                  Map<dynamic, dynamic> trial = {};
                                  if (songData != null) {
                                    trial = songData;
                                    Map newE = <dynamic, dynamic>{
                                      'url': file,
                                      'image': albumArt,
                                    };
                                    trial.addAll(newE);
                                  }

                                  await PlaylistServices().addToPlaylist(
                                      'favs',
                                      Song(
                                        id: "${trial['title']}".replaceAll(RegExp(r' '), ''),
                                        title: trial['title'],
                                        artist: trial['artist'],
                                        album: "${songs[index].album}",
                                        albumID: '',
                                        dorminantColor: Colors.deepPurpleAccent.shade700.value,
                                        darkM: Colors.deepPurpleAccent.shade700.value,
                                        lightM: Colors.deepPurple.shade600.value,
                                        syncedLyrics: <LyricLine>[LyricLine(timeTag: 0, words: "words")],
                                        artistId: '',
                                        imageURL: '',
                                        quality: '160kps',
                                        release_date: '2023',
                                        lyrics: trial['lyrics'],
                                        path: trial['url'],
                                        imagePath: '',
                                        download_date: DateTime(2023),
                                        year: 2023,
                                        duration: trial['duration'] ?? 180,
                                        picture: trial['image'],
                                        url: '',
                                        downloaded: true,
                                      ));
                                  setState(() {});
                                }
                              },
                              icon: Icon(fav!.songs.indexWhere((element) {
                                        return element.title == songs[index].title;
                                      }) ==
                                      -1
                                  ? Icons.favorite_outline
                                  : Icons.favorite)),
                          PullDownButton(
                            itemBuilder: (context) => [
                              PullDownMenuHeader(
                                  leading: QueryArtworkWidget(
                                    artworkHeight: 55,
                                    artworkWidth: 55,
                                    artworkBorder: BorderRadius.circular(15),
                                    id: songs[index].id,
                                    type: ArtworkType.AUDIO,
                                    controller: widget.state.audioQuery,
                                  ),
                                  title: songs[index].title),
                              PullDownMenuItem(
                                title: "Play",
                                onTap: () {},
                                icon: FeatherIcons.play,
                              ),
                              PullDownMenuItem(
                                title: "Add to playlist",
                                onTap: () {
                                  Box playlistsD = Hive.box<Playlists>('playList');
                                  List<Playlists> list = Hive.box<Playlists>('playList').values.toList();
                                  showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return Container(
                                          height: context.screenHeight * 0.45,
                                          width: context.screenWidth,
                                          child: ListView.builder(
                                              itemCount: list.length,
                                              itemBuilder: ((context, i) {
                                                return ListTile(
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    String file = songs[index].data;
                                                    final tagger = Audiotagger();
                                                    var songData = await tagger.readTagsAsMap(path: file);
                                                    final metaData = await MetadataRetriever.fromFile(File(file));
                                                    var albumArt = metaData.albumArt;
                                                    Map<dynamic, dynamic> trial = {};
                                                    if (songData != null) {
                                                      trial = songData;
                                                      Map newE = <dynamic, dynamic>{
                                                        'url': file,
                                                        'image': albumArt,
                                                      };
                                                      trial.addAll(newE);
                                                    }

                                                    await PlaylistServices().addToPlaylist(
                                                        list[i].id,
                                                        Song(
                                                          id: "${trial['title']}".replaceAll(RegExp(r' '), ''),
                                                          title: trial['title'],
                                                          artist: trial['artist'],
                                                          album: "${songs[index].album}",
                                                          albumID: '',
                                                          dorminantColor: Colors.deepPurpleAccent.shade700.value,
                                                          darkM: Colors.deepPurpleAccent.shade700.value,
                                                          lightM: Colors.deepPurple.shade600.value,
                                                          syncedLyrics: <LyricLine>[LyricLine(timeTag: 0, words: "words")],
                                                          artistId: '',
                                                          imageURL: '',
                                                          quality: '160kps',
                                                          release_date: '2023',
                                                          lyrics: trial['lyrics'],
                                                          path: trial['url'],
                                                          imagePath: '',
                                                          download_date: DateTime(2023),
                                                          year: 2023,
                                                          duration: trial['duration'] ?? 180,
                                                          picture: trial['image'],
                                                          url: '',
                                                          downloaded: true,
                                                        ));
                                                    setState(() {});
                                                    // await widget.state.audioQuery.pl;
                                                    // ignore: use_build_context_synchronously
                                                  },
                                                  title: Text(list[i].name),
                                                  subtitle: Text("${list[i].songs.length} songs"),
                                                );
                                              })),
                                        );
                                      });
                                },
                                icon: FeatherIcons.list,
                              ),
                              // ignore: deprecated_member_use
                              // const PullDownMenuDivider(),
                            ],
                            buttonBuilder: (context, showMenu) => CupertinoButton(
                              onPressed: showMenu,
                              padding: EdgeInsets.zero,
                              child: const Icon(FeatherIcons.moreVertical),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () async {
                      // widget.state.setLists(songs, []);
                      // await VxBottomSheet.bottomSheetView(context,
                      //     child: Play(
                      //       player: widget.player,
                      //       isOnline: false,
                      //       onLinePlaylist: false,
                      //       onlineSongData: [],
                      //       play: true,
                      //       shuffle: false,
                      //       state: widget.state,
                      //       index: index,
                      //     ),
                      //     maxHeight: 1,
                      //     minHeight: 1);
                      // setState(() {});
                      // widget.state.loadState(true);
                    },
                    title: Text(
                      songs[index].title,
                      style: const TextStyle(color: Colors.white, overflow: TextOverflow.fade),
                      maxLines: 2,
                    ),
                    leading: QueryArtworkWidget(
                      artworkHeight: 55,
                      artworkWidth: 55,
                      artworkBorder: BorderRadius.circular(15),
                      id: songs[index].id,
                      type: ArtworkType.AUDIO,
                      controller: widget.state.audioQuery,
                    ),
                    subtitle: Text(
                      "${songs[index].artist}",
                      style: const TextStyle(color: Colors.white, overflow: TextOverflow.fade),
                      maxLines: 2,
                    ),
                  ).py4(),
                );
              })
          : const CircularProgressIndicator(),
    );
  }
}
