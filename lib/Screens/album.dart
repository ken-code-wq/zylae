import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:audiotagger/audiotagger.dart';
import 'package:blur/blur.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:capped_progress_indicator/capped_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Screens/play.dart';

import '../Services/classes.dart';
import '../Services/download.dart';
import '../Widgets/songTile.dart';
import '../apis/api.dart';

class Album extends StatefulWidget {
  final String id;
  final String name;
  final String artist;
  final String asset;
  final AudioPlayer player;
  final KStates state;
  const Album({super.key, required this.id, required this.name, required this.artist, required this.asset, required this.player, required this.state});

  @override
  State<Album> createState() => _AlbumState();
}

class _AlbumState extends State<Album> {
  bool loading = true;
  bool fetched = false;
  List<String> songLinks = [];
  late Download down;
  int done = 0;

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  Map<dynamic, dynamic> songList = {};
  List musicTags = [];
  bool dispos = false;
  void disposeX() {
    dispos = true;
    _fetchSongs();
  }

  @override
  void dispose() {
    disposeX();
    super.dispose();
  }

  void _fetchSongs() async {
    if (!dispos) {
      if (!dispos) {
        setState(() {
          loading = true;
          fetched = false;
        });
      }
      songList = await SaavnAPI().fetchAlbumSongs(widget.id);
      if (!dispos) {
        setState(() {
          loading = false;
          fetched = true;
        });
      }
      for (int i = 0; songLinks.length < songList['songs'].length; i++) {
        songLinks.add(songList['songs'][i]['url']);
      }
      down = Download(songList['songs'][0]['id'].toString());
      down.addListener(() {
        setState(() {});
      });
      print(songLinks);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchSongs();
  }

  Future<void> checkPermissions() async {
    if (await Permission.storage.request().isGranted) {
      findMusicFiles();
    }
  }

  Future<void> findMusicFiles() async {
    Directory? appDocDir;
    if (Platform.isAndroid) {
      appDocDir = await getExternalStorageDirectory();
    } else if (Platform.isWindows) {
      appDocDir = await getDownloadsDirectory();
    }

    if (appDocDir != null) {
      String musicDirPath = "${appDocDir.path}/${widget.name}"; // Replace with your specific folder path

      List<FileSystemEntity> files = Directory(musicDirPath).listSync(recursive: true);

      for (var file in files) {
        if (file.path.endsWith('.m4a')) {
          if (Platform.isAndroid) {
            try {
              final tagger = Audiotagger();
              var songData = await tagger.readTagsAsMap(path: file.path);
              if (songData!.isNotEmpty) {
                final metaData = await MetadataRetriever.fromFile(File(file.path));
                var albumArt = metaData.albumArt;
                Map<dynamic, dynamic> trial = songData;
                Map newE = <dynamic, dynamic>{
                  'url': file.path,
                  'image': albumArt,
                };
                trial.addAll(newE);
                musicTags.add(trial);
              }
            } catch (e) {
              print(e);
            }
          }
        }
      }
      try {
        setState(() {
          loading = false;
        });
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color.fromARGB(0, 9, 2, 41),
      ),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 9, 2, 41),
        body: loading
            ? const CircularCappedProgressIndicator(
                strokeWidth: 7,
              ).centered()
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color.fromARGB(255, 9, 2, 41),
                      height: context.screenHeight * 0.55,
                      width: context.screenWidth,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Blur(
                            blur: 10,
                            blurColor: const Color.fromARGB(255, 9, 2, 41),
                            child: CachedNetworkImage(
                              imageUrl: widget.asset,
                              key: Key(widget.asset),
                              cacheKey: widget.asset,
                              height: context.screenHeight * 0.15,
                              fit: BoxFit.cover,
                            ).box.width(context.screenWidth).color(Colors.transparent).height(context.screenHeight * 0.45).margin(EdgeInsets.only(bottom: context.screenHeight * 0.2)).make(),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: context.screenHeight * 0.05),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.network(
                                widget.asset,
                                fit: BoxFit.cover,
                              ).box.width(context.screenWidth * 0.8).height(context.screenWidth * 0.8).make(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 2),
                        child: Column(
                          children: [
                            widget.name.text.scale(1.5).align(TextAlign.center).semiBold.make().py4(),
                            widget.artist.text.align(TextAlign.center).make().py4(),
                          ],
                        )),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              color: Colors.grey.shade800.withOpacity(.2),
                              onPressed: () async {
                                widget.state.setLists(songList['songs'], []);

                                var randomN = Random();
                                VxBottomSheet.bottomSheetView(context,
                                    child: Play(
                                      player: widget.player,
                                      isOnline: false,
                                      onLinePlaylist: false,
                                      onlineSongData: [],
                                      play: true,
                                      shuffle: true,
                                      state: widget.state,
                                      index: 0,
                                    ),
                                    maxHeight: 1,
                                    minHeight: 1);

                                widget.state.loadState(true);
                              },
                              icon: const Icon(FeatherIcons.shuffle),
                            ),
                            IconButton(
                              onPressed: () async {
                                !(down.lastDownloadId == songList['songs'].last['id']) ? widget.state.setLists(songList['songs'], []) : widget.state.setLists(musicTags, []);
                                !(down.lastDownloadId == songList['songs'].last['id'])
                                    ? await VxBottomSheet.bottomSheetView(context,
                                        child: Play(
                                          shuffle: false,
                                          player: widget.player,
                                          isOnline: true,
                                          onLinePlaylist: true,
                                          onlineSongData: songList['songs'],
                                          play: true,
                                          state: widget.state,
                                          index: 0,
                                        ),
                                        minHeight: 1,
                                        maxHeight: 1)
                                    : await VxBottomSheet.bottomSheetView(context,
                                        child: Play(
                                          shuffle: false,
                                          player: widget.player,
                                          isOnline: false,
                                          onLinePlaylist: false,
                                          onlineSongData: [],
                                          play: true,
                                          state: widget.state,
                                          index: 0,
                                        ),
                                        minHeight: 1,
                                        maxHeight: 1);

                                widget.state.loadState(true);
                              },
                              icon: const Icon(
                                Icons.play_arrow,
                                size: 60,
                              ),
                            ),
                            (down.lastDownloadId == songList['songs'].last['id'])
                                ? IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.download_done_rounded),
                                  )
                                : down.progress == 0
                                    ? IconButton(
                                        // shape: const CircleBorder(),
                                        // elevation: 0,
                                        color: Colors.grey.shade800.withOpacity(.2),
                                        onPressed: () async {
                                          for (final items in songList['songs']) {
                                            down.prepareDownload(
                                              context,
                                              items as Map,
                                              createFolder: true,
                                              folderName: widget.name,
                                            );
                                            await _waitUntilDone(items['id'].toString());
                                            setState(() {
                                              done++;
                                            });
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.download_rounded,
                                        ),
                                      )
                                    : Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Center(
                                            child: Text(
                                              down.progress == null ? '0%' : '${(100 * down.progress!).round()}%',
                                            ),
                                          ),
                                          Center(
                                            child: SizedBox(
                                              height: 30,
                                              width: 30,
                                              child: CircularProgressIndicator(
                                                value: down.progress == 1 ? null : down.progress,
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: SizedBox(
                                              height: 45,
                                              width: 45,
                                              child: CircularProgressIndicator(
                                                color: Colors.grey.shade600,
                                                value: done / songList['songs'].length,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                          ],
                        )),
                  ),
                  SliverList.builder(
                      itemCount: songList['songs'].length != 0 ? songList['songs'].length : 1,
                      itemBuilder: (context, index) {
                        return songList['songs'].length != 0
                            ? SongTile(
                                trailing: true,
                                data: songList['songs'][index],
                                index: index,
                                player: widget.player,
                                state: widget.state,
                                items: songList['songs'],
                              )
                            : "Check your internet".text.scale(2).red500.bold.makeCentered();
                      }),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                    ),
                  ),
                ],
              ),

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
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () async {
        //     widget.state.setLists(songList['songs'], []);

        //     var randomN = Random();
        //     VxBottomSheet.bottomSheetView(context,
        //         child: Play(
        //           player: widget.player,
        //           isOnline: false,
        //           onLinePlaylist: false,
        //           onlineSongData: [],
        //           play: true,
        //           shuffle: true,
        //           state: widget.state,
        //           index: 0,
        //         ),
        //         maxHeight: 1,
        //         minHeight: 1);

        //     widget.state.loadState(true);
        //   },
        //   child: Icon(Icons.play_arrow),
        // ),
      ),
    );
  }
}
