// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'dart:typed_data';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:audiotagger/audiotagger.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:zylae/Screens/play.dart';

import '../Screens/playScreeen.dart';
import '../Services/classes.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<String> musicFiles = [];
  List<Map> musicTags = [];
  List<String> musicList = [];
  List<Uint8List> musicImage = [];
  bool loading = true;
  var localMusicTags = Hive.box('library').get('localMusicTags', defaultValue: {});

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    findMusicFiles().ignore();
  }

  @override
  void initState() {
    super.initState();
    Provider.of<KStates>(context, listen: false).loadFiles ? checkPermissions() : null;
  }

  Future<void> checkPermissions() async {
    if (await Permission.storage.request().isGranted) {
      findMusicFiles();
    }
  }

  Future<void> findMusicFiles() async {
    musicTags.clear();
    musicImage.clear();
    Directory? appDocDir;
    if (Platform.isAndroid) {
      appDocDir = await getExternalStorageDirectory();
    } else if (Platform.isWindows) {
      appDocDir = await getDownloadsDirectory();
    }

    if (appDocDir != null) {
      String musicDirPath = '/storage/emulated/0/Kylae/downloads'; // Replace with your specific folder path

      List<FileSystemEntity> files = Directory(musicDirPath).listSync(recursive: true);

      for (var file in files) {
        if (file.path.endsWith('.mp3') || file.path.endsWith('.wav') || file.path.endsWith('.flac') || file.path.endsWith('.m4a')) {
          if (Platform.isAndroid) {
            try {
              final tagger = Audiotagger();
              var songData = await tagger.readTagsAsMap(path: file.path);
              if (songData!.isNotEmpty) {
                final metaData = await MetadataRetriever.fromFile(File(file.path));
                var albumArt = metaData.albumArt;
                musicImage.add(albumArt!);
                Map<dynamic, dynamic> trial = songData;
                Map newE = <dynamic, dynamic>{
                  'url': file.path,
                  'image': albumArt,
                };
                trial.addAll(newE);
                musicTags.add(trial);
                musicList.add(file.path);
              }
            } catch (e) {
              print(e);
            }
          }
        }
      }
      print('Lyric ${musicTags[0].keys.toList()}');
      Hive.box('library').put('localMusicTags', musicTags);
      try {
        setState(() {
          musicTags = musicTags.reversed.toList();
          musicList = musicList.reversed.toList();
          musicImage = musicImage.reversed.toList();
          loading = false;
          Provider.of<KStates>(context, listen: false).setLoadState(Provider.of<KStates>(context, listen: false).loadHome, false);
        });
      } catch (e) {
        print(e);
      }
    }
  }

  bool loaded = false;
  bool playing = false;
  bool error = false;
  Map info = {};
  @override
  Widget build(BuildContext context) {
    AudioPlayer _player = Provider.of<KStates>(context, listen: false).player;
    return Scaffold(
      floatingActionButton: musicList.isNotEmpty
          ? Consumer<KStates>(
              builder: (context, state, child) => FloatingActionButton(
                  onPressed: () async {
                    var randomN = Random();
                    Provider.of<KStates>(context, listen: false).setLists(musicTags, musicImage);
                    await VxBottomSheet.bottomSheetView(context,
                        child: Play(
                          player: _player,
                          isOnline: false,
                          onLinePlaylist: false,
                          onlineSongData: [],
                          play: true,
                          shuffle: true,
                          state: state,
                          index: randomN.nextInt(musicTags.length - 1),
                        ),
                        maxHeight: 1,
                        minHeight: 1);
                    Provider.of<KStates>(context, listen: false).loadState(true);
                  },
                  child: Icon(FeatherIcons.shuffle)))
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurpleAccent.shade700.withOpacity(.4),
              Colors.deepPurpleAccent.shade400.withOpacity(.2),
              Colors.deepPurpleAccent.shade200.withOpacity(.0),
              Colors.deepPurpleAccent.shade100.withOpacity(.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LiquidPullToRefresh(
          onRefresh: findMusicFiles,
          child: CustomScrollView(
            slivers: [
              SliverAppBar.medium(
                backgroundColor: Colors.transparent,
                title: "Library".text.semiBold.scale(2).make(),
              ),
              loading
                  ? SliverToBoxAdapter(child: SizedBox(height: context.screenHeight * 0.7, width: context.screenWidth, child: const CircularProgressIndicator().centered()))
                  : SliverList.builder(
                      itemCount: musicTags.length,
                      itemBuilder: (context, index) {
                        return Consumer<KStates>(
                          builder: (context, state, child) => ListTile(
                            shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.memory(musicImage[index])),
                            // trailing: IconButton(
                            //     onPressed: () async {
                            //     },
                            //     icon: Icon(FeatherIcons.trash)),
                            trailing: PullDownButton(
                              itemBuilder: (context) => [
                                PullDownMenuItem(
                                  title: "Play",
                                  onTap: () {},
                                  icon: FeatherIcons.play,
                                ),
                                // ignore: deprecated_member_use
                                // const PullDownMenuDivider(),
                                PullDownMenuItem(
                                  title: 'Delete',
                                  onTap: () async {
                                    File file = File(musicList[index]);
                                    await file.delete();
                                    print('${musicList[index]} deleted');
                                    findMusicFiles();
                                  },
                                  icon: FeatherIcons.trash2,
                                ),
                              ],
                              buttonBuilder: (context, showMenu) => CupertinoButton(
                                onPressed: showMenu,
                                padding: EdgeInsets.zero,
                                child: const Icon(FeatherIcons.moreVertical),
                              ),
                            ),
                            onTap: () async {
                              print("Trial $musicList[index]");
                              Provider.of<KStates>(context, listen: false).setLists(musicTags, musicImage);
                              await VxBottomSheet.bottomSheetView(context,
                                  child: Play(
                                    player: _player,
                                    isOnline: false,
                                    onLinePlaylist: false,
                                    onlineSongData: [],
                                    play: true,
                                    shuffle: false,
                                    state: state,
                                    index: index,
                                  ),
                                  maxHeight: 1,
                                  minHeight: 1);
                              setState(() {});
                              Provider.of<KStates>(context, listen: false).loadState(true);
                            },
                            title: Text(musicTags[index]['title'] != '' ? musicTags[index]['title'] : "<No name>"),
                            subtitle: Text(musicTags[index]['artist'] ?? "<Unknown artist>"),
                          ),
                        );
                      },
                    ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
