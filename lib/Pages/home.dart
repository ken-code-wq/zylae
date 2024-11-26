// ignore_for_file: avoid_print

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Helpers/extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../Helpers/format.dart';
import '../Screens/album.dart';
import '../Screens/artist.dart';
import '../Screens/play.dart';
import '../Screens/playlist.dart';
import '../Services/classes.dart';
import '../Services/download.dart';
import '../apis/api.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

Map data = {};
bool loading = true;
List lists = []; //Keys
List<String> list = [];
List nList = []; //Names
var homeData = Hive.box('general').get('homeData', defaultValue: {});
ConnectivityResult connectivityR = ConnectivityResult.other;

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin {
  Future<void> getHomePageData() async {
    final connectivity = await Connectivity().checkConnectivity();

    connectivityR = connectivity;
    setState(() {
      loading = true;
    });
    lists.clear();
    print("Loading");
    if (connectivity == ConnectivityResult.none) {
      data = homeData;
      for (int i = 0; i < data.keysList().length; i++) {
        if (data[data.keysList()[i]].isNotEmpty && data[data.keysList()[i]].runtimeType == List && data.keysList()[i] != 'collections') {
          lists.add(data.keysList()[i]);
          print(data[data.keysList()[i]]);
        }
      }
      setState(() {});
    } else {
      Map recievedData = await SaavnAPI().fetchHomePageData();
      data = recievedData;
      if (mounted) {
        setState(() {});
      }
      recievedData = await FormatResponse.formatPromoLists(data);
      if (recievedData.isNotEmpty) {
        data = recievedData;
        Hive.box('general').put('homeData', data);
        print(Hive.box('general').get('homeData'));
        for (int i = 0; i < data.keysList().length; i++) {
          if (data[data.keysList()[i]].isNotEmpty && data[data.keysList()[i]].runtimeType == List && data.keysList()[i] != 'collections') {
            lists.add(data.keysList()[i]);
            print(data[data.keysList()[i]]);
          }
        }
        print(data[lists]);
      }
    }
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
    print(data.entries);
  }

  @override
  bool get wantKeepAlive => true;

  void pe() async {
    await Permission.storage.request();
    var status = await Permission.storage.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    // The param 'retryRequest' is false, by default.
    // _hasPermission = await _audioQuery.checkAndRequest(
    //   retryRequest: retry,
    // );
  }

  @override
  void initState() {
    super.initState();
    pe();
  }

  String preferredDownloadQuality = '320 kbps';
  late Download down;

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  void _album(String id, String name, String asset, String artist, KStates state, AudioPlayer _player) {
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

  void _artist(String id, String token, String name, String asset, KStates state, AudioPlayer _player) {
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

  void _playlist(String id, String asset, String name, KStates state, AudioPlayer _player) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    AudioPlayer _player = Provider.of<KStates>(context, listen: false).player;

    // print(data['new_trending'].length);
    return Consumer<KStates>(
      builder: (context, state, child) => Container(
        decoration: const BoxDecoration(
            // color: Color.fromRGBO(35, 24, 52, 1),
            color: Color.fromARGB(255, 10, 10, 10)
            // gradient: LinearGradient(
            //   colors: [
            //     Colors.deepPurpleAccent.shade700.withOpacity(.4),
            //     Colors.deepPurpleAccent.shade400.withOpacity(.2),
            //     Colors.deepPurpleAccent.shade200.withOpacity(.0),
            //     Colors.deepPurpleAccent.shade100.withOpacity(.0),
            //   ],
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            // ),
            ),
        child: LiquidPullToRefresh(
          onRefresh: getHomePageData,
          child: FutureBuilder(
            future: SaavnAPI().fetchHomePageData(),
            builder: (context, data) {
              if (data.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ).box.height(context.screenHeight * 0.5).width(context.screenWidth).make(),
                );
              } else if (data.connectionState == ConnectionState.none) {
                return SizedBox(
                  height: context.screenHeight * 0.4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FeatherIcons.xOctagon, size: 50),
                      SizedBox(height: 25),
                      "Check your internet connection".text.scale(1.4).makeCentered(),
                    ],
                  ),
                );
              } else if (data.connectionState == ConnectionState.done) {
                if (data.hasData) {
                  Map recievedData = {};
                  recievedData = data.data!;
                  // recievedData = await FormatResponse.formatPromoLists(data);
                  lists.clear();
                  if (recievedData.isNotEmpty) {
                    Hive.box('general').put('homeData', recievedData);
                    for (int i = 0; i < recievedData.keysList().length; i++) {
                      if (recievedData[recievedData.keysList()[i]].isNotEmpty && recievedData[recievedData.keysList()[i]].runtimeType == List && recievedData.keysList()[i] != 'collections') {
                        lists.add(recievedData.keysList()[i]);
                        print(recievedData[recievedData.keysList()[i]]);
                      }
                    }
                    print(recievedData[lists]);
                    print(lists.length);
                  }
                  return CustomScrollView(
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Column(
                                  children: [
                                    SizedBox(
                                      height: context.screenHeight * 0.05,
                                      width: context.screenWidth,
                                    ),
                                    AppBar(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      // title: "Kylae".text.semiBold.make(),
                                      centerTitle: true,
                                      leading: const Icon(EvaIcons.options),
                                      actions: [const Icon(Icons.person_rounded).px12()],
                                    ),
                                    SizedBox(
                                      height: context.screenHeight * 0.08,
                                      width: context.screenWidth,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: ["Welcome".text.bold.make(), "Enjoy your music :)".text.semiBold.scale(1.4).make()],
                                      ).px16(),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        print(data.data!['collections']);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 15),
                                        height: 50,
                                        width: context.screenWidth,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: Colors.white,
                                        ),
                                        padding: const EdgeInsets.only(left: 6),
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            const Icon(
                                              EvaIcons.search,
                                              color: Vx.gray600,
                                            ),
                                            "Search songs, artists, albums or playlists".text.gray600.make().px4(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      SliverList.builder(
                        itemCount: lists.length,
                        itemBuilder: ((context, index) {
                          var item = recievedData.isNotEmpty ? recievedData[lists[index]] : {};
                          return recievedData.isNotEmpty
                              ? SizedBox(
                                  height: context.screenHeight * 0.25,
                                  width: context.screenWidth,
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            lists[index].toString().firstLetterUpperCase().replaceAll(RegExp(r'_'), ' '),
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                          ).px12(),
                                        ],
                                      ),
                                      SizedBox(
                                        height: context.screenHeight * 0.2,
                                        width: context.screenWidth,
                                        child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: recievedData[lists[index]].length,
                                            itemBuilder: (context, i) {
                                              try {
                                                return item[i]['type'] != 'song'
                                                    ? InkWell(
                                                        onTap: () {
                                                          if (item[i]['type'] == 'album') {
                                                            _album(item[i]['id'], item[i]['title'], item[i]['image'], '', state, _player);
                                                          } else if (item[i]['type'] == 'playlist') {
                                                            _playlist(item[i]['id'], item[i]['image'], item[i]['title'], state, _player);
                                                          } else if (item[i]['type'] == 'artist') {
                                                            _artist(item[i]['id'], item[i]['artistToken'], item[i]['title'], item[i]['image'], state, _player);
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
                                                                  imageUrl: item[i]['image'],
                                                                  key: Key(item[i]['image']),
                                                                  cacheKey: item[i]['image'],
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
                                                                  "${item[i]['title']}".unescape(),
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
                                                          Provider.of<KStates>(context, listen: false).setLists([item[i]], []);
                                                          await VxBottomSheet.bottomSheetView(context,
                                                              child: Play(
                                                                player: _player,
                                                                isOnline: true,
                                                                shuffle: false,
                                                                onLinePlaylist: false,
                                                                onlineSongData: [item[i]],
                                                                play: true,
                                                                state: state,
                                                                index: 0,
                                                              ),
                                                              maxHeight: 1,
                                                              minHeight: 1);
                                                          // ignore: use_build_context_synchronously
                                                          Provider.of<KStates>(context, listen: false).loadState(true);
                                                        },
                                                        child: Container(
                                                          width: context.screenWidth * 0.35,
                                                          // color: Colors.amber,
                                                          alignment: Alignment.topCenter,
                                                          child: Stack(
                                                            alignment: Alignment.bottomCenter,
                                                            children: [
                                                              Container(
                                                                alignment: Alignment.center,
                                                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                                width: context.screenWidth * 0.3,
                                                                // child: Text(item[i]['title']),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.deepPurple.shade800,
                                                                  shape: BoxShape.circle,
                                                                  image: DecorationImage(
                                                                    image: NetworkImage(
                                                                      item[i]['image'],
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
                                                                item[i]['title'],
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
                                  ),
                                )
                              : InkWell(
                                  onTap: () {
                                    getHomePageData();
                                  },
                                  child: const Icon(
                                    Icons.replay,
                                    size: 50,
                                  ).centered().box.height(context.screenHeight * 0.4).makeCentered(),
                                );
                        }),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 150,
                        ),
                      ),
                    ],
                  );
                } else {
                  return "No data found".text.make();
                }
              } else if (data.connectionState == ConnectionState.none) {
                return SizedBox(
                  height: context.screenHeight * 0.4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FeatherIcons.xOctagon, size: 50),
                      SizedBox(height: 25),
                      "Check your internet connection".text.scale(1.4).makeCentered(),
                    ],
                  ),
                );
              } else {
                return "Error".text.make();
              }
            },
          ),
        ),
      ).box.color(ThemeData.dark(useMaterial3: true).scaffoldBackgroundColor).make(),
    );
  }
}
