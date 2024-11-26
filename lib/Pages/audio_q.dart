// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Screens/play.dart';

import '../Screens/loacal_playlist.dart';
import '../Screens/local_artists.dart';
import '../Services/QueryServices.dart';
import '../Services/classes.dart';
import '../Widgets/playlist_artwork.dart';

class AudioQ extends StatefulWidget {
  const AudioQ({Key? key}) : super(key: key);

  @override
  _AudioQState createState() => _AudioQState();
}

class _AudioQState extends State<AudioQ> with AutomaticKeepAliveClientMixin {
  // Main method.
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Indicate if application has permission to the library.
  bool _hasPermission = false;
  bool loaded = false;
  List<SongModel> songs = [];
  List<AlbumModel> albums = [];
  List<PlaylistModel> playlists = [];
  List playlist = [];
  List<ArtistModel> artists = [];

  List persons = [];
  List alb = [];
  List songs2 = [];
  int tab = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // (Optinal) Set logging level. By default will be set to 'WARN'.
    //
    // Log will appear on:
    //  * XCode: Debug Console
    //  * VsCode: Debug Console
    //  * Android Studio: Debug and Logcat Console
    LogConfig logConfig = LogConfig(logType: LogType.ERROR);
    _audioQuery.setLogConfig(logConfig);

    // Check and request for permission.
    checkAndRequestPermissions();
  }

  checkAndRequestPermissions({bool retry = false}) async {
    await Permission.storage.request();
    var status = await Permission.storage.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    // The param 'retryRequest' is false, by default.
    _hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: retry,
    );
    _hasPermission ? setState(() {}) : null;

    // Only call update the UI if application has all required permissions.
    print(await Hive.box<Playlists>('playList').values);

    songs = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
      path: '/storage/emulated/0/Kylae',
    );

    for (SongModel song in songs) {
      alb.add(song.album);
      persons.add(song.artist);
      String file = song.data;
      final tagger = Audiotagger();
      var songData = await tagger.readTagsAsMap(path: file);
      final metaData = await MetadataRetriever.fromFile(File(file));
      var albumArt = metaData.albumArt;

      if (songData != null) {
        Map<dynamic, dynamic> trial = songData!;
        Map newE = <dynamic, dynamic>{
          'url': file,
          'image': albumArt,
        };
        trial.addAll(newE);
        songs2.add(trial);
      }
    }
    print("Done");
    albums = await _audioQuery.queryAlbums();
    artists = await _audioQuery.queryArtists();
    if (mounted) {
      setState(() {
        loaded = true;
      });
    }
  }

  checkAlbum() async {
    setState(() {
      loaded = false;
    });
    setState(() {
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    AudioPlayer _player = Provider.of<KStates>(context, listen: false).player;

    // _audioQuery.querySongs();
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 10, 10, 10),
      // appBar: AppBar(
      //   title: "Library".text.semiBold.scale(2).make(),
      //   backgroundColor: Colors.red.withOpacity(.0),
      //   elevation: 2,
      // ),
      body: Consumer<KStates>(
        builder: (context, state, child) => Center(
          child: DefaultTabController(
            length: 4,
            child: !_hasPermission
                ? noAccessToLibraryWidget()
                : loaded
                    ? SizedBox(
                        height: context.screenHeight,
                        width: context.screenWidth,
                        child: ListView(
                          children: [
                            AppBar(
                              title: "Library".text.semiBold.scale(2).make(),
                              backgroundColor: Colors.transparent,
                              elevation: 2,
                              surfaceTintColor: Colors.transparent,
                              // foregroundColor: Colors.transparent,
                            ),
                            const TabBar(
                              tabs: [
                                Tab(
                                  text: "Songs",
                                  icon: Icon(FeatherIcons.music),
                                ),
                                Tab(
                                  text: "Albums",
                                  icon: Icon(FeatherIcons.disc),
                                ),
                                Tab(
                                  text: "Artists",
                                  icon: Icon(FeatherIcons.mic),
                                ),
                                Tab(
                                  text: "Playlists",
                                  icon: Icon(FeatherIcons.list),
                                ),
                              ],
                            ),
                            TabBarView(children: [songTab(_player, state), albumTab(_player, state), artistTab(_player, state), playlistTab(_player, state)]).box.height(context.screenHeight - 255).width(context.screenWidth).make(),
                          ],
                        ),
                      )
                    : albums.isNotEmpty || songs.isNotEmpty || playlists.isNotEmpty || artists.isNotEmpty
                        ? InkWell(
                            onTap: () {},
                            child: const Text("Nothing"),
                          )
                        : const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget songTab(_player, state) {
    return songs.isNotEmpty
        ? ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == songs.length - 1 ? 120 : 0),
                child: ListTile(
                  trailing: PullDownButton(
                    itemBuilder: (context) => [
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
                                            print(list[i].id);
                                            await PlaylistServices().addToPlaylist(
                                                list[i].id,
                                                Song(
                                                  id: "${songs2[index]['title']}".replaceAll(RegExp(r' '), ''),
                                                  title: songs2[index]['title'],
                                                  artist: songs2[index]['artist'],
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
                                                  lyrics: songs2[index]['lyrics'],
                                                  path: songs2[index]['url'],
                                                  imagePath: '',
                                                  download_date: DateTime(2023),
                                                  year: 2023,
                                                  duration: songs2[index]['duration'] ?? 180,
                                                  picture: songs2[index]['image'],
                                                  url: '',
                                                  downloaded: true,
                                                ));
                                            // await _audioQuery.pl;
                                            // ignore: use_build_context_synchronously
                                            Navigator.pop(context);
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
                      PullDownMenuItem(
                        title: 'Delete',
                        onTap: () async {
                          File file = File(songs2[index]['url']);
                          await file.delete();
                          checkAndRequestPermissions();
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
                    Provider.of<KStates>(context, listen: false).setLists(songs2, []);
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
                  title: Text(
                    songs[index].title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  leading: QueryArtworkWidget(
                    id: songs[index].id,
                    type: ArtworkType.AUDIO,
                    controller: _audioQuery,
                  ),
                  subtitle: Text(
                    "${songs[index].artist}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ).py4(),
              );
            })
        : const CircularProgressIndicator();
  }

  Widget albumTab(_player, state) {
    return ListView.builder(
        itemCount: albums.length + 1,
        itemBuilder: (context, index) {
          return index != albums.length
              ? alb.contains(albums[index].album)
                  ? ListTile(
                      leading: QueryArtworkWidget(
                        id: albums[index].id,
                        type: ArtworkType.ALBUM,
                      ),
                      title: Text(albums[index].album),
                      subtitle: Text('${albums[index].numOfSongs} songs'),
                    )
                  : const Row()
              : const SizedBox(
                  height: 120,
                );
        });
  }

  Widget playlistTab(_player, state) {
    Box playlistsD = Hive.box<Playlists>('playList');
    List<Playlists> list = Hive.box<Playlists>('playList').values.toList();
    print(list);
    // print(Hive.box<Playlists>('playList').values.toList()[1].toMap());
    return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 110.0),
          child: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController _playlistName = TextEditingController();
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    title: Text(
                      'Create a new playlist',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _playlistName,
                        ).px12()
                      ],
                    ),
                    actions: [
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: "Cancel".text.red500.make(),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_playlistName.text.trim() != '') {
                                PlaylistServices().createPlaylist(_playlistName.text.trim(), author: "You");
                                Navigator.pop(context);
                                _playlistName.clear();
                              }
                            },
                            child: "Create".text.make(),
                          ).px16().py4(),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
            tooltip: 'Add playlist',
            icon: const Icon(FeatherIcons.plus),
          ),
        ),
        body: ValueListenableBuilder(
            valueListenable: Hive.box<Playlists>('playList').listenable(),
            builder: (context, data, child) {
              if (data.isNotEmpty) {
                return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(childAspectRatio: 0.9, crossAxisCount: 2),
                    itemCount: playlistsD.length == 0 ? 1 : playlistsD.length,
                    itemBuilder: (context, index) {
                      return playlistsD.length != index
                          ? playlistsD.length != 0
                              // ? ListTile(
                              //     // onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => LocalPlaylist(name: playlists[index].playlist, id: playlists[index].id, audioQuery: _audioQuery, player: _player, states: state))),
                              //     // leading: QueryArtworkWidget(
                              //     //   id: playlists[index].id,
                              //     //   type: ArtworkType.PLAYLIST,
                              //     // ),
                              //     title: Text(Hive.box<Playlists>('playList').values.toList()[index].name),
                              //     subtitle: Text('${Hive.box<Playlists>('playList').values.toList()[index].songs.length} songs'),
                              //   )
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 18.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                              builder: (context) => LocalPlaylist(
                                                    player: _player,
                                                    states: state,
                                                    list: data.values.toList()[index],
                                                  )));
                                    },
                                    child: SizedBox(
                                      height: context.screenHeight * 0.2,
                                      width: context.screenWidth * 0.45,
                                      child: Column(
                                        children: [
                                          Container(
                                            height: context.screenHeight * 0.2 * (2 / 3),
                                            margin: const EdgeInsets.symmetric(horizontal: 15),
                                            decoration: BoxDecoration(color: data.values.toList()[index].id != 'favs' ? Colors.deepPurpleAccent.shade700.withOpacity(.1) : Colors.red.shade500.withOpacity(.4), borderRadius: BorderRadius.circular(16)),
                                            child: data.values.toList()[index].songs.isEmpty
                                                ? data.values.toList()[index].id != 'favs'
                                                    ? const Icon(
                                                        FeatherIcons.list,
                                                        size: 50,
                                                      ).centered()
                                                    : const Icon(
                                                        Icons.favorite_rounded,
                                                        size: 50,
                                                      ).centered()
                                                : ClipRRect(
                                                    borderRadius: BorderRadius.circular(15),
                                                    child: FourPicArtwork(
                                                      height: context.screenHeight * 0.2 * (2 / 3),
                                                      songs: data.values.toList()[index].songs,
                                                      width: (context.screenWidth * 0.45) - 12,
                                                    ),
                                                  ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              data.values.toList()[index].name.text.scale(1.2).semiBold.makeCentered(),
                                              Text("${data.values.toList()[index].songs.length} songs"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: SizedBox(
                                      height: 50,
                                      child: Column(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10.0),
                                                    ),
                                                    title: Text(
                                                      'Create a new playlist',
                                                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [const TextField().px12()],
                                                    ),
                                                    actions: [
                                                      Column(
                                                        children: [
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                            child: "Cancel".text.make(),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            },
                                                            child: "Create".text.make(),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            tooltip: 'Add playlist',
                                            icon: const Icon(FeatherIcons.plus),
                                          ),
                                          "Add new playlist".text.medium.make()
                                        ],
                                      )),
                                )
                          : const SizedBox(
                              height: 120,
                            );
                    });
              } else {
                return "Nothing found".text.makeCentered();
              }
            }));
  }

  Widget artistTab(_player, state) {
    return ListView.builder(
        itemCount: artists.length + 1,
        itemBuilder: (context, index) {
          return index != artists.length
              ? ListTile(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => LocalArtist(
                                  audioQuery: _audioQuery,
                                  id: artists[index].id,
                                  player: _player,
                                  states: state,
                                )));
                  },
                  subtitle: Text("${artists[index].numberOfTracks.toString()} songs"),
                  leading: QueryArtworkWidget(
                    id: artists[index].id,
                    type: ArtworkType.ARTIST,
                  ),
                  title: Text(artists[index].artist),
                )
              : const SizedBox(
                  height: 120,
                );
        });
  }

  Widget noAccessToLibraryWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.redAccent.withOpacity(0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Application doesn't have access to the library"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => checkAndRequestPermissions(retry: true),
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }
}
