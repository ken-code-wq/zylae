// ignore_for_file: empty_catches, no_leading_underscores_for_local_identifiers

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../APIs/spotify_api.dart';
import '../Screens/album.dart';
import '../Screens/artist.dart';
import '../Screens/playlist.dart';
import '../Screens/video_player.dart';
import '../Services/classes.dart';
import '../Services/download.dart';
import '../Widgets/songTile.dart';
import '../apis/api.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin {
  static String YT_API_KEY = "AIzaSyD9pDeSbJyjo5BaKQsp314uw-ZTjZvSez8";
  YoutubeAPI yt = YoutubeAPI(YT_API_KEY, maxResults: 70, type: "video");
  TextEditingController _textController = TextEditingController();
  bool loading = false;
  bool fetched = false;
  List recon = [];
  List<String> reconS = [];
  int reccCount = 0;
  List<Map<dynamic, dynamic>> searchedList = [];
  List<Map> albumList = [];
  List<Map> playlistsList = [];
  List<Map> artistsList = [];
  List<YT_API> ytList = [];

  Map songList = {};
  var history = Hive.box('history');
  List histories = [];
  int results = 1;
  bool showList = false;
  bool refresh = false;

  Map iconB = {'artist': Icons.person, 'playlist': Icons.playlist_play_rounded, 'song': Icons.music_note, 'album': Icons.album};

  void _cancel() {
    setState(() {
      loading = false;
      fetched = true;
    });
  }

  void _incrementCounter(String search, String type, bool clear) async {
    // print(search);
    // var token = await SpotifyApi().getAccessToken();
    // print(token);
    // var results = await SpotifyApi().searchTrack(accessToken: token.toString(), query: "Baby justin beiber");
    // print("results $results");
    if (clear) {
      searchedList.clear();
      songList.clear();
      albumList.clear();
      playlistsList.clear();
      artistsList.clear();
    }
    refresh = true;
    setState(() {
      loading = true;
      fetched = false;
      showList = true;
    });
    history.values.contains(search) ? null : history.add(search);
    histories = [];
    histories.addAll(history.values);
    if (type == 'All') {
      try {
        if (searchedList.isEmpty) {
          searchedList = await SaavnAPI().fetchSearchResults(search);
        }
        for (final element in searchedList) {
          if (element['title'] != 'Top Result') {
            element['allowViewAll'] = true;
          }
        }
        recon.clear();
        reconS.clear();
        for (int i = 0; i < searchedList.length; i++) {
          reconS.add(searchedList[i]['title']);
          recon.add(searchedList[i]['items'].length);
          reccCount = reccCount + int.parse(searchedList[i]['items'].length.toString());
          // print(recon);
        }
        setState(() {
          loading = false;
          fetched = true;
        });
      } catch (e) {
        print(e);
      }
    } else if (type == 'Songs') {
      setState(() {
        loading = true;
        fetched = false;
        showList = true;
      });
      songList = await SaavnAPI().fetchSongSearchResults(searchQuery: search);
      print(songList);

      setState(() {
        loading = false;
        fetched = true;
      });
    } else if (type == 'Albums') {
      try {
        setState(() {
          loading = true;
          fetched = false;
          showList = true;
        });
        albumList = await SaavnAPI().fetchAlbums(searchQuery: search, type: 'album');
        print(albumList);
        setState(() {
          loading = false;
          fetched = true;
        });
      } catch (e) {}
    } else if (type == 'Playlists') {
      try {
        setState(() {
          loading = true;
          fetched = false;
          showList = true;
        });
        playlistsList = await SaavnAPI().fetchAlbums(searchQuery: search, type: 'playlist');
        print(playlistsList);
        setState(() {
          loading = false;
          fetched = true;
        });
      } catch (e) {}
    } else if (type == 'Artists') {
      try {
        setState(() {
          loading = true;
          fetched = false;
          showList = true;
        });
        artistsList = await SaavnAPI().fetchAlbums(searchQuery: search, type: 'artist');
        print(artistsList);
        setState(() {
          loading = false;
          fetched = true;
        });
      } catch (e) {}
    } else if (type == 'YT') {
      try {
        setState(() {
          loading = true;
          fetched = false;
          showList = true;
        });
        ytList = await yt.search(search);
        print(ytList);
        setState(() {
          loading = false;
          fetched = true;
        });
      } catch (e) {}
    }
  }

  void _albumP(String id, String name, String asset, String artist, AudioPlayer _player, KStates state) {
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
          player: _player,
          state: state,
        ),
      ),
    );
  }

  void _artistP(String id, String token, String name, String asset, AudioPlayer _player, KStates state) {
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
          player: _player,
          state: state,
        ),
      ),
    );
  }

  void _playlistP(String id, String asset, String name, AudioPlayer _player, KStates state) {
    // Provider.of<KStates>(context, listen: false).setData(id: id, album: '', image: asset, artistName: '', token: '', name: name, type: 'playlist', url: '');
    // Provider.of<KStates>(context, listen: false).setCP(6);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PlayList(
          id: id,
          asset: asset,
          name: name,
          player: _player,
          state: state,
        ),
      ),
    );
  }

  // // ignore: unused_element
  // void _ge(String search, String type) async {
  //   setState(() {
  //     loading = true;
  //     fetched = false;
  //   });
  //   List new_trending = [];
  //   try {
  //     if(type == '' )
  //     setState(() {
  //       loading = false;
  //       fetched = true;
  //     });

  //   } catch (e) {
  //     // ignore: avoid_print
  //     print(e);
  //   }
  // }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    AudioPlayer _player = Provider.of<KStates>(context, listen: false).player;
    histories.clear();
    histories.addAll(history.values);
    List types = [
      "Video",
      "All",
      "Songs",
      "Albums",
      "Playlists",
      "Artists",
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color.fromARGB(0, 15, 11, 24),
      ),
      child: Consumer<KStates>(
        builder: (context, state, child) => Container(
          decoration: const BoxDecoration(color: Color.fromARGB(255, 10, 10, 10)),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: 45,
                  width: context.screenWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.only(left: 6),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: Colors.grey.shade800),
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(color: Colors.black),
                      prefixIcon: Icon(
                        FeatherIcons.search,
                        color: Vx.gray600,
                      ),
                      prefixIconColor: Vx.gray600,
                      border: InputBorder.none,
                      hintText: "Search songs, artists, albums or playlists",
                      hintStyle: TextStyle(color: Vx.gray600, fontWeight: FontWeight.w400),
                    ),
                    onSubmitted: (value) {
                      // _textController.clear();
                      _incrementCounter(value, types[results], true);
                    },
                  ),
                ).box.width(context.screenWidth).padding(const EdgeInsets.only(top: 80)).make(),
              ),
              SliverToBoxAdapter(
                child: !showList
                    ? const Text("")
                    : SizedBox(
                        height: 50,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: types.length,
                            itemBuilder: ((context, i) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(50),
                                onTap: () {
                                  if (types[i] == 'All') {
                                    searchedList.isEmpty ? _incrementCounter(_textController.text.trim(), types[i], false) : _cancel();
                                  } else if (types[i] == 'Songs') {
                                    songList.isEmpty ? _incrementCounter(_textController.text.trim(), types[i], false) : _cancel();
                                  }
                                  if (types[i] == 'Albums') {
                                    albumList.isEmpty ? _incrementCounter(_textController.text.trim(), types[i], false) : _cancel();
                                  }
                                  if (types[i] == 'Playlists') {
                                    playlistsList.isEmpty ? _incrementCounter(_textController.text.trim(), types[i], false) : _cancel();
                                  }
                                  if (types[i] == 'Artists') {
                                    artistsList.isEmpty ? _incrementCounter(_textController.text.trim(), types[i], false) : _cancel();
                                  }
                                  if (types[i] == 'Video') {
                                    ytList.isEmpty ? _incrementCounter(_textController.text.trim(), 'YT', false) : _cancel();
                                  }
                                  setState(() {
                                    results = i;
                                  });
                                },
                                child: Chip(
                                  avatar: i == 0
                                      ? Icon(
                                          FeatherIcons.video,
                                          color: results == 0 ? Colors.white : Colors.deepPurple.shade100,
                                        )
                                      : i == 1
                                          ? null
                                          : i == 2
                                              ? const Icon(FeatherIcons.music)
                                              : i == 3
                                                  ? const Icon(FeatherIcons.disc)
                                                  : i == 4
                                                      ? const Icon(FeatherIcons.list)
                                                      : const Icon(FeatherIcons.mic),
                                  label: Text(
                                    types[i],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Vx.white,
                                    ),
                                  ),
                                  side: results != i ? BorderSide.none : const BorderSide(color: Colors.white, width: 2),
                                  backgroundColor: i != 0
                                      ? results == i
                                          ? Colors.deepPurple.shade400
                                          : const Color.fromARGB(255, 9, 2, 41)
                                      : results == i
                                          ? Colors.redAccent
                                          : Colors.deepPurple.shade900,
                                  shape: const StadiumBorder(),
                                ).px4(),
                              );
                            })),
                      ),
              ),
              results == 1
                  ? _allResults(_player, types, state)
                  : results == 2
                      ? _songs(_player, state)
                      : results == 3
                          ? _lists(_player, 'album', state)
                          : results == 4
                              ? _lists(_player, 'playlist', state)
                              : results == 5
                                  ? _artist(_player, state)
                                  : _yt(),
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

  Widget _allResults(AudioPlayer _player, List types, KStates state) {
    return SliverList.builder(
        itemCount: loading
            ? 1
            : !fetched
                ? 1
                : searchedList.length,
        itemBuilder: (context, indexx) {
          return fetched
              ? searchedList.isNotEmpty
                  ? ExpansionTile(
                      leading: Icon(
                        iconB[reconS[indexx].eliminateLast.toLowerCase()],
                      ),
                      maintainState: true,
                      backgroundColor: Colors.deepPurpleAccent[500],
                      shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      initiallyExpanded: true,
                      title: reconS[indexx].text.make(),
                      children: List.generate(recon[indexx], (index) {
                        return SongTile(
                          trailing: false,
                          data: searchedList[indexx]['items'][index],
                          index: index,
                          player: _player,
                          state: state,
                          items: searchedList[indexx]['items'],
                        );
                      }),
                    )
                  : InkWell(
                      onTap: () {
                        _incrementCounter(_textController.text.trim(), 'All', false);
                      },
                      child: Center(
                        child: Icon(FeatherIcons.refreshCw),
                      ),
                    )
              : loading
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ).box.height(context.screenHeight * (1 - 0.21)).makeCentered()
                  : Wrap(
                      children: List.generate(
                        histories.length,
                        (index) => InkWell(
                          onTap: () {
                            _incrementCounter(histories[index], 'All', true);
                            _textController.text = histories[index];
                          },
                          child: Chip(
                            label: Text(
                              histories[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            side: BorderSide.none,
                            backgroundColor: Colors.deepPurple.shade400,
                            shape: const StadiumBorder(),
                          ).px4(),
                        ),
                      ),
                    ).px8();
        });
  }

  Widget _songs(AudioPlayer _player, KStates state) {
    return SliverList.builder(
      itemCount: loading
          ? 1
          : !fetched
              ? 1
              : songList.length,
      itemBuilder: ((context, index) {
        return fetched
            ? songList['error'] == ''
                ? SongTile(
                    data: songList['songs'][index],
                    trailing: false,
                    index: index,
                    player: _player,
                    state: state,
                    items: songList['songs'],
                  )
                : InkWell(
                    onTap: () {
                      _incrementCounter(_textController.text.trim(), 'Songs', false);
                    },
                    child: Center(
                      child: Icon(FeatherIcons.refreshCw),
                    ),
                  )
            : loading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CircularProgressIndicator()],
                  ).box.height(context.screenHeight * (1 - 0.21)).makeCentered()
                : const Text("X");
      }),
    );
  }

  Widget _lists(AudioPlayer _player, String type, KStates state) {
    return type == 'playlist'
        ? SliverGrid.builder(
            itemCount: loading
                ? 1
                : !fetched
                    ? 1
                    : playlistsList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemBuilder: ((context, index) {
              return fetched && playlistsList.isNotEmpty
                  ? InkWell(
                      onTap: () {
                        _playlistP(playlistsList[index]['id'], playlistsList[index]['image'], playlistsList[index]['title'], _player, state);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(FeatherIcons.image).centered(),
                            Image.network(
                              playlistsList[index]['image'],
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ).px8().py8()
                  : loading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [CircularProgressIndicator()],
                        ).box.height(context.screenHeight * (1 - 0.21)).makeCentered()
                      : const Text("X");
            }),
          )
        : SliverGrid.builder(
            itemCount: loading
                ? 1
                : !fetched
                    ? 1
                    : (albumList.length ~/ 2) + (albumList.length % 2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, childAspectRatio: 0.9),
            itemBuilder: ((context, index) {
              return fetched
                  ? InkWell(
                      onTap: () {
                        _albumP(albumList[index]['id'], albumList[index]['title'], albumList[index]['image'], albumList[index]['artist'], _player, state);
                      },
                      child: SizedBox(
                        height: context.screenHeight * 0.2,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                albumList[index]['image'],
                                height: context.screenHeight * 0.2,
                                fit: BoxFit.cover,
                                width: context.screenWidth * 0.4,
                              ),
                            ).py4(),
                            Text(
                              albumList[index]['title'],
                              maxLines: 2,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ).px4()
                          ],
                        ),
                      ))
                  : loading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [CircularProgressIndicator()],
                        ).box.height(context.screenHeight * (1 - 0.21)).makeCentered()
                      : const Text("X");
            }),
          );
  }

  Widget _artist(AudioPlayer _player, KStates state) {
    return SliverGrid.builder(
      itemCount: loading
          ? 1
          : !fetched
              ? 1
              : artistsList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemBuilder: ((context, index) {
        return fetched && artistsList.isNotEmpty
            ? InkWell(
                onTap: () {
                  _artistP(artistsList[index]['artistId'], artistsList[index]['artistToken'], artistsList[index]['title'], artistsList[index]['image'], _player, state);
                },
                child: SizedBox(
                  height: context.screenWidth * 0.35,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        width: context.screenWidth * 0.3,
                        height: context.screenWidth * 0.3,
                        decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(artistsList[index]['image']), fit: BoxFit.cover)),
                      ),
                      Text(
                        artistsList[index]['title'],
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
              )
            : loading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CircularProgressIndicator()],
                  ).box.height(context.screenHeight * (1 - 0.21)).makeCentered()
                : const Text("X");
      }),
    );
  }

  Widget _yt() {
    return SliverList.builder(
        itemCount: loading
            ? 1
            : !fetched
                ? 1
                : ytList.length,
        itemBuilder: (context, index) {
          return fetched
              ? InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => Video(
                                  data: ytList[index],
                                  id: '${ytList[index].id}',
                                )));
                  },
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                        child: Image.network(
                          ytList[index].thumbnail!['high']["url"],
                          width: double.maxFinite,
                          fit: BoxFit.cover,
                          height: context.screenHeight * 0.24,
                        ).box.gray300.make(),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  "${ytList[index].title}".text.scale(1.3).maxLines(2).semiBold.make(),
                                  // "${ytList[index].publishedAt}".text.maxLines(4).make(),
                                ],
                              ).box.width(context.screenWidth * 0.7).height(double.maxFinite).make().px8(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).box.height(context.screenHeight * 0.3).width(double.maxFinite).px8.make().py8(),
                )
              : loading
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ).box.height(context.screenHeight * (1 - 0.21)).makeCentered()
                  : const Text("X");
        });
  }
}
