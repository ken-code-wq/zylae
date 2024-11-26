import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:velocity_x/velocity_x.dart';

import '../Screens/downloads.dart';
import '../Screens/loacal_playlist.dart';
import '../Services/QueryServices.dart';
import '../Services/classes.dart';
import '../Widgets/playlist_artwork.dart';

class Libre extends StatefulWidget {
  const Libre({super.key});

  @override
  State<Libre> createState() => _LibreState();
}

class _LibreState extends State<Libre> {
  @override
  Widget build(BuildContext context) {
    AudioPlayer _player = Provider.of<KStates>(context, listen: false).player;
    Playlists? fav = Hive.box<Playlists>('playList').get('favs');
    return Consumer<KStates>(builder: (context, state, child) {
      state.audioQuery.checkAndRequest();
      return FutureBuilder(
          future: state.audioQuery.querySongs(
            sortType: SongSortType.DATE_ADDED,
            orderType: OrderType.ASC_OR_SMALLER,
            uriType: UriType.EXTERNAL,
            ignoreCase: true,
            path: '/storage/emulated/0/Kylae',
          ),
          builder: (context, s) {
            if (s.hasData) {
              return ValueListenableBuilder(
                  valueListenable: Hive.box<Playlists>('playList').listenable(),
                  builder: (context, value, child) {
                    return Scaffold(
                      appBar: AppBar(
                        title: "Library".text.semiBold.scale(2).make(),
                        backgroundColor: Colors.transparent,
                        elevation: 2,
                        surfaceTintColor: Colors.transparent,
                        actions: [
                          Icon(FeatherIcons.search),
                          InkWell(
                            onTap: () {
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
                            child: Chip(
                              label: "Add new playlist".text.make(),
                              avatar: Icon(Icons.add),
                              shape: StadiumBorder(),
                              side: BorderSide.none,
                            ).px4(),
                          ),
                        ],
                      ),
                      // floatingActionButton: Padding(
                      //   padding: const EdgeInsets.only(bottom: 110.0),
                      //   child: Container(
                      //     height: 55,
                      //     width: 55,
                      //     decoration: BoxDecoration(color: Colors.deepPurpleAccent.shade200.withOpacity(.5), borderRadius: BorderRadius.circular(8)),
                      //     child: IconButton(
                      //       onPressed: () {
                      //         showDialog(
                      //           context: context,
                      //           builder: (BuildContext context) {
                      //             TextEditingController _playlistName = TextEditingController();
                      //             return AlertDialog(
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(10.0),
                      //               ),
                      //               title: Text(
                      //                 'Create a new playlist',
                      //                 style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      //               ),
                      //               content: Column(
                      //                 mainAxisSize: MainAxisSize.min,
                      //                 children: [
                      //                   TextField(
                      //                     controller: _playlistName,
                      //                   ).px12()
                      //                 ],
                      //               ),
                      //               actions: [
                      //                 Row(
                      //                   children: [
                      //                     ElevatedButton(
                      //                       onPressed: () {
                      //                         Navigator.pop(context);
                      //                       },
                      //                       child: "Cancel".text.red500.make(),
                      //                     ),
                      //                     ElevatedButton(
                      //                       onPressed: () {
                      //                         if (_playlistName.text.trim() != '') {
                      //                           PlaylistServices().createPlaylist(_playlistName.text.trim(), author: "You");
                      //                           Navigator.pop(context);
                      //                           _playlistName.clear();
                      //                         }
                      //                       },
                      //                       child: "Create".text.make(),
                      //                     ).px16().py4(),
                      //                   ],
                      //                 ),
                      //               ],
                      //             );
                      //           },
                      //         );
                      //       },
                      //       tooltip: 'Add playlist',
                      //       icon: const Icon(FeatherIcons.plus),
                      //     ),
                      //   ),
                      // ),
                      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
                      body: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => Downloads(
                                      player: _player,
                                      state: state,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                height: context.screenHeight * 0.12,
                                width: context.screenWidth,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: double.maxFinite,
                                      margin: const EdgeInsets.all(4),
                                      alignment: Alignment.center,
                                      width: context.screenWidth * 0.32,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade600.withOpacity(.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.airplanemode_active,
                                        size: 40,
                                        color: Colors.blue.shade800.withOpacity(.9),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        "Downloads".text.scale(1.2).semiBold.make().px12(),
                                        "${s.data!.length} songs".text.make().px12(),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ).py8(),
                          ),
                          SliverToBoxAdapter(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => LocalPlaylist(
                                      player: _player,
                                      states: state,
                                      list: fav,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                height: context.screenHeight * 0.12,
                                width: context.screenWidth,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: double.maxFinite,
                                      alignment: Alignment.center,
                                      width: context.screenWidth * 0.32,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: fav!.songs.isEmpty
                                            ? const Icon(
                                                Icons.favorite_rounded,
                                                size: 50,
                                              ).centered()
                                            : Stack(
                                                children: [
                                                  FourPicArtwork(
                                                    height: context.screenHeight * 0.12,
                                                    songs: fav.songs,
                                                    width: (context.screenWidth * .32),
                                                  ),
                                                  Icon(
                                                    Icons.favorite_rounded,
                                                    size: 50,
                                                    color: Colors.white,
                                                  ).centered()
                                                ],
                                              ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        "Favourites".text.scale(1.2).semiBold.make().px12(),
                                        "${fav.songs.length} songs".text.make().px12(),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverList.builder(
                              itemCount: value.length,
                              itemBuilder: (context, index) {
                                if (value.values.toList()[index].id != 'favs') {
                                  return InkWell(
                                    onTap: () {
                                      value.values.toList()[index].author == "You"
                                          ? Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                builder: (context) => LocalPlaylist(
                                                  player: _player,
                                                  states: state,
                                                  list: value.values.toList()[index],
                                                ),
                                              ),
                                            )
                                          : Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                builder: (context) => LocalPlaylist(
                                                  player: _player,
                                                  states: state,
                                                  list: value.values.toList()[index],
                                                ),
                                              ),
                                            );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 10),
                                      height: context.screenHeight * 0.12,
                                      width: context.screenWidth,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: double.maxFinite,
                                            alignment: Alignment.center,
                                            width: context.screenWidth * 0.32,
                                            child: value.values.toList()[index].author == "You"
                                                ? value.values.toList()[index].songs.isEmpty
                                                    ? value.values.toList()[index].id != 'favs'
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
                                                          height: context.screenHeight * 0.12,
                                                          songs: value.values.toList()[index].songs,
                                                          width: (context.screenWidth * .32),
                                                        ),
                                                      )
                                                : ClipRRect(
                                                    borderRadius: BorderRadius.circular(15),
                                                    child: CachedNetworkImage(
                                                      imageUrl: value.values.toList()[index].imageURL ?? "",
                                                      cacheKey: value.values.toList()[index].imageURL ?? "",
                                                      height: context.screenHeight * 0.12,
                                                      width: (context.screenWidth * .32),
                                                    ),
                                                  ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              value.values.toList()[index].name.text.scale(1.2).semiBold.make().px12(),
                                              "${value.values.toList()[index].songs.length} songs".text.make().px12(),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ).py8();
                                } else {
                                  return Row();
                                }
                              }),
                        ],
                      ),
                    );
                  });
            } else {
              return CircularProgressIndicator().centered();
            }
          });
    });
  }
}
