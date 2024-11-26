import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:hive/hive.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'Pages/audio_q.dart';
import 'Pages/blackhole_my_music.dart';
import 'Pages/home.dart';
import 'Pages/libr.dart';
import 'Screens/play.dart';
import 'Services/aSHelper.dart';
import 'Services/classes.dart';
import 'Pages/search.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.black.withOpacity(0.002),
  ));
  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(PlaylistsAdapter());
  Hive.registerAdapter(LyricLineAdapter());
  await Hive.openBox('settings');
  await Hive.openBox('general');
  // ignore: body_might_complete_normally_catch_error
  await Hive.openBox<Playlists>('playList');
  if (Hive.box<Playlists>('playList').isEmpty) {
    Hive.box<Playlists>('playList').put('favs', Playlists(id: 'favs', name: "Favorites", songs: [], added: DateTime.now(), modified: DateTime.now(), author: "Z", imageURL: ''));
  }
  await Hive.openBox<Song>('song');
  await Hive.openBox('history');
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  await Hive.openBox('library');
  await Hive.openBox('ytlinkcache');
  await Hive.openBox('stats');
  await Hive.openBox('downloads');
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final audioHandlerHelper = AudioHandlerHelper();
  final AudioPlayerHandler audioHandler = await audioHandlerHelper.getAudioHandler();
  GetIt.I.registerSingleton<AudioPlayerHandler>(audioHandler);
  await setOptimalDisplayMode();
  runApp(const MyApp());
}

Future<void> setOptimalDisplayMode() async {
  await FlutterDisplayMode.setHighRefreshRate();
  // final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  // final DisplayMode active = await FlutterDisplayMode.active;

  // final List<DisplayMode> sameResolution = supported
  //     .where(
  //       (DisplayMode m) => m.width == active.width && m.height == active.height,
  //     )
  //     .toList()
  //   ..sort(
  //     (DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate),
  //   );

  // final DisplayMode mostOptimalMode =
  //     sameResolution.isNotEmpty ? sameResolution.first : active;

  // await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zylae',
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: ChangeNotifierProvider(create: (_) => KStates(), child: const MyHomePage(title: 'Flutter Demo Home Page')),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

int currentPage = 0;
double hD = 0;

class _MyHomePageState extends State<MyHomePage> {
  var generalBox = Hive.box('general');
  bool _visible = true;
  int cs = 0;
  @override
  Widget build(BuildContext context) {
    AudioPlayer _player = Provider.of<KStates>(context, listen: false).player;
    // generalBox.clear();
    if (generalBox.isEmpty) {
      generalBox.add('Name');
      generalBox.add([]);
      generalBox.add([]);
    }
    return Consumer<KStates>(builder: (context, state, child) {
      List<Widget> pages = [
        //0
        const Home(),
        //1
        const Search(),
        const Libre(),
        //2
        DownloadedSongs()
        // const AudioQ(),
        // const Home(),
        //3
      ];
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Color.fromARGB(0, 15, 11, 24),
        ),
        child: DefaultTabController(
          length: 4,
          child: Scaffold(
            // floatingActionButton: state.isLoaded
            //     ? FloatingActionButton.extended(
            //         backgroundColor: Colors.transparent,
            //         onPressed: () {},
            //         label: Container(
            //           height: 120,
            //           width: context.screenWidth,
            //           child: StreamBuilder(
            //               stream: _player.positionStream,
            //               builder: (context, snapshot1) {
            //                 // getOnlineInfo(playing);

            //                 final Duration duration = state.isLoaded ? _player.position : const Duration(seconds: 0);
            //                 return InkWell(
            //                   onTap: () async {
            //                     await VxBottomSheet.bottomSheetView(context,
            //                         child: Play(
            //                           player: _player,
            //                           isOnline: "${state.tags[_player.sequenceState!.currentIndex]['url']}".contains('http'),
            //                           onLinePlaylist: false,
            //                           onlineSongData: [],
            //                           play: false,
            //                           shuffle: false,
            //                           state: state,
            //                           index: _player.sequenceState!.currentIndex,
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
            //                         state.tags.isNotEmpty
            //                             ? ClipRRect(
            //                                 borderRadius: BorderRadius.circular(15),
            //                                 child: state.isLoaded
            //                                     ? state.tags[_player.sequenceState!.currentIndex]['image'].runtimeType != String
            //                                         ? Image.memory(
            //                                             state.tags[_player.sequenceState!.currentIndex]['image'],
            //                                             height: 60,
            //                                             width: 60,
            //                                             fit: BoxFit.cover,
            //                                           )
            //                                         : Image.network(
            //                                             state.tags[_player.sequenceState!.currentIndex]['image'],
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
            //                           children: [
            //                             state.isLoaded
            //                                 ? Text(
            //                                     state.tags[_player.sequenceState!.currentIndex]['title'],
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
            //                             state.isLoaded
            //                                 ? Text(
            //                                     state.tags[_player.sequenceState!.currentIndex]['artist'],
            //                                     maxLines: 1,
            //                                   )
            //                                 : ''.text.make(),
            //                           ],
            //                         ).px8().py2().box.width(context.screenWidth * 0.44).make(),
            //                         const Spacer(),
            //                         Row(
            //                           children: [
            //                             state.isLoaded
            //                                 ? IconButton(
            //                                     onPressed: () {
            //                                       if (_player.playing) {
            //                                         setState(() {
            //                                           _player.pause();
            //                                         });
            //                                       } else {
            //                                         setState(() {
            //                                           _player.play();
            //                                         });
            //                                       }
            //                                     },
            //                                     icon: Icon(
            //                                       _player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            //                                       size: 30,
            //                                       color: Colors.white,
            //                                     ))
            //                                 : IconButton(onPressed: () {}, icon: Icon(Icons.replay)),
            //                             state.isLoaded
            //                                 ? IconButton(
            //                                     onPressed: () async {
            //                                       _player.hasNext ? await _player.seekToNext() : null;
            //                                       _player.play();

            //                                       setState(() {});
            //                                     },
            //                                     icon: Icon(
            //                                       Icons.fast_forward_rounded,
            //                                       color: _player.hasNext ? Colors.white : Colors.grey.shade600,
            //                                       size: 20,
            //                                     ))
            //                                 : "".text.make(),
            //                           ],
            //                         )
            //                       ],
            //                     ).py2().px2(),
            //                   ),
            //                 );
            //               }).box.width(context.screenWidth * 0.9).makeCentered(),
            //         ),
            //       )
            //     : Row(),
            // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            extendBodyBehindAppBar: true,
            body: SlidingUpPanel(
                onPanelSlide: (value) {
                  setState(() {
                    hD = value;
                  });
                },
                renderPanelSheet: true,
                color: Colors.transparent,
                controller: state.panelController,
                maxHeight: context.screenHeight,
                minHeight: state.isLoaded ? 80 : 0,
                panel: state.isLoaded && hD >= 0.1
                    ? Play(
                        player: _player,
                        isOnline: "${state.tags[_player.sequenceState!.currentIndex]['url']}".contains('http'),
                        onLinePlaylist: false,
                        onlineSongData: [],
                        play: false,
                        shuffle: false,
                        state: state,
                        index: _player.sequenceState!.currentIndex,
                      )
                    : Row(),
                collapsed: state.isLoaded
                    ? FloatingActionButton.extended(
                        backgroundColor: Colors.transparent,
                        onPressed: () {},
                        label: "".text.make(),
                        // label: Container(
                        //   height: 120,
                        //   width: context.screenWidth,
                        //   child: StreamBuilder(
                        //       stream: _player.positionStream,
                        //       builder: (context, snapshot1) {
                        //         // getOnlineInfo(playing);

                        //         final Duration duration = state.isLoaded ? _player.position : const Duration(seconds: 0);
                        //         return InkWell(
                        //           onTap: () async {
                        //             await VxBottomSheet.bottomSheetView(context,
                        //                 child: Play(
                        //                   player: _player,
                        //                   isOnline: "${state.tags[_player.sequenceState!.currentIndex]['url']}".contains('http'),
                        //                   onLinePlaylist: false,
                        //                   onlineSongData: [],
                        //                   play: false,
                        //                   shuffle: false,
                        //                   state: state,
                        //                   index: _player.sequenceState!.currentIndex,
                        //                 ),
                        //                 maxHeight: 1,
                        //                 minHeight: 1);
                        //           },
                        //           child: Container(
                        //             height: 62,
                        //             width: context.percentWidth,
                        //             decoration: BoxDecoration(color: const Color.fromARGB(255, 45, 8, 96), borderRadius: BorderRadius.circular(12)),
                        //             child: Row(
                        //               children: [
                        //                 state.tags.isNotEmpty
                        //                     ? ClipRRect(
                        //                         borderRadius: BorderRadius.circular(15),
                        //                         child: state.isLoaded
                        //                             ? state.tags[_player.sequenceState!.currentIndex]['image'].runtimeType != String
                        //                                 ? Image.memory(
                        //                                     state.tags[_player.sequenceState!.currentIndex]['image'],
                        //                                     height: 60,
                        //                                     width: 60,
                        //                                     fit: BoxFit.cover,
                        //                                   )
                        //                                 : Image.network(
                        //                                     state.tags[_player.sequenceState!.currentIndex]['image'],
                        //                                     height: 60,
                        //                                     width: 60,
                        //                                     fit: BoxFit.cover,
                        //                                   )
                        //                             : Image.asset(
                        //                                 'assets/tune.png',
                        //                                 height: 60,
                        //                                 width: 60,
                        //                                 fit: BoxFit.cover,
                        //                               ),
                        //                       )
                        //                     : ClipRRect(
                        //                         borderRadius: BorderRadius.circular(15),
                        //                         child: Image.asset(
                        //                           'assets/tune.png',
                        //                           height: 60,
                        //                           width: 60,
                        //                           fit: BoxFit.cover,
                        //                         ),
                        //                       ),
                        //                 Column(
                        //                   crossAxisAlignment: CrossAxisAlignment.start,
                        //                   mainAxisAlignment: MainAxisAlignment.center,
                        //                   children: [
                        //                     state.isLoaded
                        //                         ? Text(
                        //                             state.tags[_player.sequenceState!.currentIndex]['title'],
                        //                             maxLines: 2,
                        //                             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        //                           )
                        //                         : const Text(
                        //                             "Nothing playing",
                        //                             style: TextStyle(
                        //                               fontSize: 18,
                        //                               fontWeight: FontWeight.w500,
                        //                             ),
                        //                           ),
                        //                     state.isLoaded
                        //                         ? Text(
                        //                             state.tags[_player.sequenceState!.currentIndex]['artist'],
                        //                             maxLines: 1,
                        //                           )
                        //                         : ''.text.make(),
                        //                   ],
                        //                 ).px8().py2().box.width(context.screenWidth * 0.44).make(),
                        //                 const Spacer(),
                        //                 Row(
                        //                   children: [
                        //                     state.isLoaded
                        //                         ? IconButton(
                        //                             onPressed: () {
                        //                               if (_player.playing) {
                        //                                 setState(() {
                        //                                   _player.pause();
                        //                                 });
                        //                               } else {
                        //                                 setState(() {
                        //                                   _player.play();
                        //                                 });
                        //                               }
                        //                             },
                        //                             icon: Icon(
                        //                               _player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        //                               size: 30,
                        //                               color: Colors.white,
                        //                             ))
                        //                         : IconButton(onPressed: () {}, icon: Icon(Icons.replay)),
                        //                     state.isLoaded
                        //                         ? IconButton(
                        //                             onPressed: () async {
                        //                               _player.hasNext ? await _player.seekToNext() : null;
                        //                               _player.play();

                        //                               setState(() {});
                        //                             },
                        //                             icon: Icon(
                        //                               Icons.fast_forward_rounded,
                        //                               color: _player.hasNext ? Colors.white : Colors.grey.shade600,
                        //                               size: 20,
                        //                             ))
                        //                         : "".text.make(),
                        //                   ],
                        //                 )
                        //               ],
                        //             ).py4().px2(),
                        //           ),
                        //         );
                        //       }).box.width(context.screenWidth * 0.9).makeCentered(),
                        // ),
                      )
                    // Container(
                    //     height: 80,
                    //     width: context.screenWidth,
                    //     color: Colors.red,
                    //     // margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    //     child: StreamBuilder(
                    //         stream: _player.positionStream,
                    //         builder: (context, snapshot1) {
                    //           try {
                    //             cs = _player.sequenceState!.currentIndex;
                    //           } catch (e) {
                    //             print(e);
                    //           }

                    //           // getOnlineInfo(playing);

                    //           final Duration duration = state.isLoaded ? _player.position : const Duration(seconds: 0);
                    //           return Row(
                    //             children: [
                    //               InkWell(
                    //                 onTap: () async {
                    //                   await VxBottomSheet.bottomSheetView(context,
                    //                       child: Play(
                    //                         player: _player,
                    //                         isOnline: "${state.tags[_player.sequenceState!.currentIndex]['url']}".contains('http'),
                    //                         onLinePlaylist: false,
                    //                         onlineSongData: [],
                    //                         play: false,
                    //                         shuffle: false,
                    //                         state: state,
                    //                         index: _player.sequenceState!.currentIndex,
                    //                       ),
                    //                       maxHeight: 1,
                    //                       minHeight: 1);
                    //                 },
                    //                 child: Container(
                    //                   height: 80,
                    //                   child: Row(
                    //                     children: [
                    //                       state.tags.isNotEmpty
                    //                           ? ClipRRect(
                    //                               borderRadius: BorderRadius.circular(15),
                    //                               child: state.isLoaded
                    //                                   ? state.tags[cs]['image'].runtimeType != String
                    //                                       ? Image.memory(
                    //                                           state.tags[cs]['image'],
                    //                                           height: 60,
                    //                                           width: 60,
                    //                                           fit: BoxFit.cover,
                    //                                         )
                    //                                       : Image.network(
                    //                                           state.tags[cs]['image'],
                    //                                           height: 60,
                    //                                           width: 60,
                    //                                           fit: BoxFit.cover,
                    //                                         )
                    //                                   : Image.asset(
                    //                                       'assets/tune.png',
                    //                                       height: 60,
                    //                                       width: 60,
                    //                                       fit: BoxFit.cover,
                    //                                     ),
                    //                             )
                    //                           : ClipRRect(
                    //                               borderRadius: BorderRadius.circular(15),
                    //                               child: Image.asset(
                    //                                 'assets/tune.png',
                    //                                 height: 60,
                    //                                 width: 60,
                    //                                 fit: BoxFit.cover,
                    //                               ),
                    //                             ),
                    //                       Column(
                    //                         crossAxisAlignment: CrossAxisAlignment.start,
                    //                         children: [
                    //                           state.isLoaded
                    //                               ? Text(
                    //                                   state.tags[cs]['title'],
                    //                                   maxLines: 1,
                    //                                 )
                    //                               : const Text(
                    //                                   "Nothing playing",
                    //                                   style: TextStyle(
                    //                                     fontSize: 18,
                    //                                     fontWeight: FontWeight.w500,
                    //                                   ),
                    //                                 ),
                    //                           state.isLoaded
                    //                               ? Text(
                    //                                   state.tags[cs]['artist'],
                    //                                   maxLines: 2,
                    //                                 )
                    //                               : ''.text.make(),
                    //                         ],
                    //                       ).px8().py4().box.width(context.screenWidth * 0.5).make(),
                    //                       const Spacer(),
                    //                       state.isLoaded
                    //                           ? IconButton(
                    //                               onPressed: () {
                    //                                 if (_player.playing) {
                    //                                   setState(() {
                    //                                     _player.pause();
                    //                                   });
                    //                                 } else {
                    //                                   setState(() {
                    //                                     _player.play();
                    //                                   });
                    //                                 }
                    //                                 cs = _player.sequenceState!.currentIndex;
                    //                               },
                    //                               icon: Icon(
                    //                                 _player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    //                                 size: 30,
                    //                                 color: Colors.white,
                    //                               ))
                    //                           : IconButton(onPressed: () {}, icon: Icon(Icons.replay)),
                    //                       state.isLoaded
                    //                           ? IconButton(
                    //                               onPressed: () async {
                    //                                 _player.hasNext ? await _player.seekToNext() : null;
                    //                                 cs = _player.sequenceState!.currentIndex;
                    //                                 _player.play();

                    //                                 setState(() {});
                    //                               },
                    //                               icon: Icon(
                    //                                 Icons.fast_forward_rounded,
                    //                                 color: _player.hasNext ? Colors.white : Colors.grey.shade600,
                    //                                 size: 20,
                    //                               ))
                    //                           : "".text.make(),
                    //                     ],
                    //                   ).px8().py8(),
                    //                 ),
                    //               ).expand(),
                    //             ],
                    //           );
                    //         }),
                    //   )
                    : Row(),
                body: pages[state.currentPage]),
            bottomNavigationBar: AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              height: 130 * (1 - hD),
              color: const Color.fromARGB(255, 20, 15, 30),
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  NavigationBar(
                    backgroundColor: Color.fromARGB(255, 15, 11, 24),
                    elevation: 0,
                    destinations: [
                      const NavigationDestination(icon: Icon(EvaIcons.music), label: 'For you').px(2.5),
                      const NavigationDestination(icon: Icon(EvaIcons.search), label: 'Search').px(2.5),
                      const NavigationDestination(icon: Icon(EvaIcons.list), label: 'Library').px(2.5),
                      const NavigationDestination(icon: Icon(Icons.settings), label: 'Settings').px(2.5),
                    ],
                    indicatorColor: Colors.deepPurple.shade400,
                    selectedIndex: currentPage,
                    onDestinationSelected: (value) {
                      // Provider.of<ThemeModal>(context, listen: false).setCoin(generalBox.getAt(1));
                      setState(() {
                        currentPage = value;
                        Provider.of<KStates>(context, listen: false).setCP(value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
