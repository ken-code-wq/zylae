import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Screens/play.dart';

import '../Services/QueryServices.dart';
import '../Services/classes.dart';
import '../Services/play_service.dart';
import '../Widgets/playlist_artwork.dart';

class LocalPlaylist extends StatefulWidget {
  final Playlists list;
  final AudioPlayer player;
  final KStates states;
  const LocalPlaylist({super.key, required this.player, required this.states, required this.list});

  @override
  State<LocalPlaylist> createState() => _LocalPlaylistState();
}

class _LocalPlaylistState extends State<LocalPlaylist> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> songs = [];
  int total_time = 0;
  List songs2 = [];
  bool loaded = false;
  getSongs() async {
    for (Song song in widget.list.songs) {
      Map additional = {};
      String file = "${song.path}";
      // final tagger = Audiotagger();
      // var songData = await tagger.readTagsAsMap(path: file);
      final metaData = await MetadataRetriever.fromFile(File(file));
      var albumArt = metaData.albumArt;
      if (albumArt!.isNotEmpty) {
        Map<dynamic, dynamic> trial = {};
        Map newE = <dynamic, dynamic>{
          'artist': song.artist,
          'title': song.title,
          'lyrics': song.lyrics,
          'synced_lyrics': song.syncedLyrics,
          'url': song.path,
          'image': song.picture,
          'duration': metaData.trackDuration,
        };
        total_time = total_time + ((metaData.trackDuration ?? 0) / 1000).round().toInt();
        trial.addAll(newE);
        songs2.add(trial);
        // print(trial);
        // print(trial.keysList());
      }
      print("TT is $total_time");
    }
    setState(() {
      loaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: widget.states.isLoaded
      //     ? FloatingActionButton.extended(
      //         backgroundColor: Colors.transparent,
      //         onPressed: () {},
      //         label: Container(
      //           height: 120,
      //           width: context.screenWidth,
      //           child: StreamBuilder(
      //               stream: widget.player.positionStream,
      //               builder: (context, snapshot1) {
      //                 // getOnlineInfo(playing);

      //                 final Duration duration = widget.states.isLoaded ? widget.player.position : const Duration(seconds: 0);
      //                 return InkWell(
      //                   onTap: () async {
      //                     await VxBottomSheet.bottomSheetView(context,
      //                         child: Play(
      //                           player: widget.player,
      //                           isOnline: "${widget.states.tags[widget.player.sequenceState!.currentIndex]['url']}".contains('http'),
      //                           onLinePlaylist: false,
      //                           onlineSongData: [],
      //                           play: false,
      //                           shuffle: false,
      //                           state: widget.states,
      //                           index: widget.player.sequenceState!.currentIndex,
      //                         ),
      //                         maxHeight: 1,
      //                         minHeight: 1);
      //                   },
      //                   child: Container(
      //                     height: 62,
      //                     width: context.percentWidth,
      //                     decoration: BoxDecoration(color: const Color.fromARGB(255, 45, 8, 96), borderRadius: BorderRadius.circular(12)),
      //                     child: Row(
      //                       children: [
      //                         widget.states.tags.isNotEmpty
      //                             ? ClipRRect(
      //                                 borderRadius: BorderRadius.circular(15),
      //                                 child: widget.states.isLoaded
      //                                     ? widget.states.tags[widget.player.sequenceState!.currentIndex]['image'].runtimeType != String
      //                                         ? Image.memory(
      //                                             widget.states.tags[widget.player.sequenceState!.currentIndex]['image'],
      //                                             height: 60,
      //                                             width: 60,
      //                                             fit: BoxFit.cover,
      //                                           )
      //                                         : Image.network(
      //                                             widget.states.tags[widget.player.sequenceState!.currentIndex]['image'],
      //                                             height: 60,
      //                                             width: 60,
      //                                             fit: BoxFit.cover,
      //                                           )
      //                                     : Image.asset(
      //                                         'assets/tune.png',
      //                                         height: 60,
      //                                         width: 60,
      //                                         fit: BoxFit.cover,
      //                                       ),
      //                               )
      //                             : ClipRRect(
      //                                 borderRadius: BorderRadius.circular(15),
      //                                 child: Image.asset(
      //                                   'assets/tune.png',
      //                                   height: 60,
      //                                   width: 60,
      //                                   fit: BoxFit.cover,
      //                                 ),
      //                               ),
      //                         Column(
      //                           crossAxisAlignment: CrossAxisAlignment.start,
      //                           mainAxisAlignment: MainAxisAlignment.center,
      //                           children: [
      //                             widget.states.isLoaded
      //                                 ? Text(
      //                                     widget.states.tags[widget.player.sequenceState!.currentIndex]['title'],
      //                                     maxLines: 2,
      //                                     style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      //                                   )
      //                                 : const Text(
      //                                     "Nothing playing",
      //                                     style: TextStyle(
      //                                       fontSize: 18,
      //                                       fontWeight: FontWeight.w500,
      //                                     ),
      //                                   ),
      //                             widget.states.isLoaded
      //                                 ? Text(
      //                                     widget.states.tags[widget.player.sequenceState!.currentIndex]['artist'],
      //                                     maxLines: 1,
      //                                   )
      //                                 : ''.text.make(),
      //                           ],
      //                         ).px8().py2().box.width(context.screenWidth * 0.44).make(),
      //                         const Spacer(),
      //                         Row(
      //                           children: [
      //                             widget.states.isLoaded
      //                                 ? IconButton(
      //                                     onPressed: () {
      //                                       if (widget.player.playing) {
      //                                         setState(() {
      //                                           widget.player.pause();
      //                                         });
      //                                       } else {
      //                                         setState(() {
      //                                           widget.player.play();
      //                                         });
      //                                       }
      //                                     },
      //                                     icon: Icon(
      //                                       widget.player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
      //                                       size: 30,
      //                                       color: Colors.white,
      //                                     ))
      //                                 : IconButton(onPressed: () {}, icon: Icon(Icons.replay)),
      //                             widget.states.isLoaded
      //                                 ? IconButton(
      //                                     onPressed: () async {
      //                                       widget.player.hasNext ? await widget.player.seekToNext() : null;
      //                                       widget.player.play();

      //                                       setState(() {});
      //                                     },
      //                                     icon: Icon(
      //                                       Icons.fast_forward_rounded,
      //                                       color: widget.player.hasNext ? Colors.white : Colors.grey.shade600,
      //                                       size: 20,
      //                                     ))
      //                                 : "".text.make(),
      //                           ],
      //                         )
      //                       ],
      //                     ).py4().px2(),
      //                   ),
      //                 );
      //               }).box.width(context.screenWidth * 0.9).makeCentered(),
      //         ),
      //       )
      //     : Row(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Color.fromARGB(255, 10, 10, 10),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: Hive.box<Playlists>('playList').listenable(),
              builder: (context, data, child) {
                List<Song> songs = data.values.toList()[data.values.toList().indexWhere((element) => element.id == widget.list.id)].songs;
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.15),
                        child: SizedBox(
                          height: context.screenHeight * 0.3,
                          width: context.screenWidth,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FourPicArtwork(
                                height: context.screenHeight * 0.3,
                                width: context.screenWidth * 0.7,
                                songs: songs,
                              ),
                            ),
                          ),
                        ).py64(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          widget.list.name.text.headline3(context).align(TextAlign.left).make(),
                          Column(
                            children: [
                              ElevatedButton(
                                  onPressed: () async {
                                    // widget.states.setLists(songs2, []);
                                    // await VxBottomSheet.bottomSheetView(context,
                                    //     child: Play(
                                    //       player: widget.player,
                                    //       isOnline: false,
                                    //       onLinePlaylist: false,
                                    //       onlineSongData: [],
                                    //       play: true,
                                    //       shuffle: true,
                                    //       state: widget.states,
                                    //       index: 0,
                                    //     ),
                                    //     maxHeight: 1,
                                    //     minHeight: 1);
                                    // setState(() {});
                                    // widget.states.loadState(true);
                                  },
                                  child: Text("Shuffle"))
                            ],
                          )
                        ],
                      ).px12(),
                    ),
                    SliverList.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          Song item = songs[index];
                          return !songs.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.only(bottom: index == songs.length - 1 ? 120 : 0),
                                  child: ListTile(
                                    onLongPress: () async {
                                      await PlaylistServices().removeFromPlaylist(
                                        'favs',
                                        index,
                                      );
                                      setState(() {});
                                      songs2.removeAt(index);
                                      widget.states.setLists(songs2, []);
                                    },
                                    onTap: () async {
                                      // PlayerInvoke.init(
                                      //   songsList: List.generate(songs2.length, (index) => {

                                      //   };),
                                      //   index: index,
                                      //   isOffline: true,
                                      //   fromDownloads: true,
                                      //   recommend: false,
                                      // );
                                      // widget.states.setLists(songs2, []);
                                      // await VxBottomSheet.bottomSheetView(context,
                                      //     child: Play(
                                      //       player: widget.player,
                                      //       isOnline: false,
                                      //       onLinePlaylist: false,
                                      //       onlineSongData: [],
                                      //       play: true,
                                      //       shuffle: false,
                                      //       state: widget.states,
                                      //       index: index,
                                      //     ),
                                      //     maxHeight: 1,
                                      //     minHeight: 1);
                                      // setState(() {});
                                      // widget.states.loadState(true);
                                    },
                                    title: Text(
                                      item.title,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          item.picture,
                                          height: 60,
                                          width: 60,
                                          fit: BoxFit.cover,
                                        )),
                                    subtitle: Text(
                                      "${item.artist}",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ).py4())
                              : "No songs".text.makeCentered();
                        }),
                    SliverToBoxAdapter(
                      child: Center(
                        child: "${Duration(seconds: total_time).inMinutes} minutes ${Duration(seconds: total_time).inSeconds - (60 * Duration(seconds: total_time).inMinutes)} seconds".text.make(),
                      ).py32(),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                      ),
                    ),
                  ],
                );
              }),
    );
  }
}
