import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Screens/play.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

import '../Services/classes.dart';

class LocalArtist extends StatefulWidget {
  final int id;
  final OnAudioQuery audioQuery;
  final AudioPlayer player;
  final KStates states;
  const LocalArtist({super.key, required this.audioQuery, required this.id, required this.player, required this.states});

  @override
  State<LocalArtist> createState() => _LocalArtistState();
}

class _LocalArtistState extends State<LocalArtist> {
  List all = [];
  List songs2 = [];
  bool loaded = false;

  getAll() async {
    all = await widget.audioQuery.queryAudiosFrom(AudiosFromType.ARTIST_ID, widget.id);
    // widget.audioQuery.
    for (SongModel song in all) {
      Map additional = {};
      String file = song.data;
      final tagger = Audiotagger();
      var songData = await tagger.readTagsAsMap(path: file);
      final metaData = await MetadataRetriever.fromFile(File(file));
      var albumArt = metaData.albumArt;
      Map<dynamic, dynamic> trial = songData!;
      Map newE = <dynamic, dynamic>{
        'url': file,
        'image': albumArt,
      };
      trial.addAll(newE);
      songs2.add(trial);
    }
    setState(() {
      loaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.states.isLoaded
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

                      final Duration duration = widget.states.isLoaded ? widget.player.position : const Duration(seconds: 0);
                      return InkWell(
                        onTap: () async {
                          await VxBottomSheet.bottomSheetView(context,
                              child: Play(
                                player: widget.player,
                                isOnline: "${widget.states.tags[widget.player.sequenceState!.currentIndex]['url']}".contains('http'),
                                onLinePlaylist: false,
                                onlineSongData: [],
                                play: false,
                                shuffle: false,
                                state: widget.states,
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
                              widget.states.tags.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: widget.states.isLoaded
                                          ? widget.states.tags[widget.player.sequenceState!.currentIndex]['image'].runtimeType != String
                                              ? Image.memory(
                                                  widget.states.tags[widget.player.sequenceState!.currentIndex]['image'],
                                                  height: 60,
                                                  width: 60,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  widget.states.tags[widget.player.sequenceState!.currentIndex]['image'],
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
                                  widget.states.isLoaded
                                      ? Text(
                                          widget.states.tags[widget.player.sequenceState!.currentIndex]['title'],
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
                                  widget.states.isLoaded
                                      ? Text(
                                          widget.states.tags[widget.player.sequenceState!.currentIndex]['artist'],
                                          maxLines: 1,
                                        )
                                      : ''.text.make(),
                                ],
                              ).px8().py2().box.width(context.screenWidth * 0.44).make(),
                              const Spacer(),
                              Row(
                                children: [
                                  widget.states.isLoaded
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
                                  widget.states.isLoaded
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: context.screenHeight * 0.4,
              width: context.screenWidth,
              child: Center(
                child: QueryArtworkWidget(
                  id: widget.id,
                  type: ArtworkType.ARTIST,
                  artworkHeight: context.screenHeight * 0.35,
                  artworkWidth: context.screenHeight * 0.35,
                ),
              ),
            ).py12(),
          ),
          SliverList.builder(
              itemCount: all.length,
              itemBuilder: (context, index) {
                SongModel item = all[index];
                return Padding(
                    padding: EdgeInsets.only(bottom: index == all.length - 1 ? 120 : 0),
                    child: ListTile(
                      onTap: () async {
                        widget.states.setLists(songs2, []);
                        await VxBottomSheet.bottomSheetView(context,
                            child: Play(
                              player: widget.player,
                              isOnline: false,
                              onLinePlaylist: false,
                              onlineSongData: [],
                              play: true,
                              shuffle: false,
                              state: widget.states,
                              index: index,
                            ),
                            maxHeight: 1,
                            minHeight: 1);
                        setState(() {});
                        widget.states.loadState(true);
                      },
                      title: Text(
                        item.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      leading: QueryArtworkWidget(
                        id: item.id,
                        type: ArtworkType.AUDIO,
                        controller: widget.audioQuery,
                      ),
                      subtitle: Text(
                        "${item.artist}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ).py4());
              })
        ],
      ),
    );
  }
}
