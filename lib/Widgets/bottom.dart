// import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
// import 'package:eva_icons_flutter/eva_icons_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:provider/provider.dart';
// import 'package:sliding_up_panel/sliding_up_panel.dart';
// import 'package:velocity_x/velocity_x.dart';

// import '../Screens/play.dart';
// import '../Services/classes.dart';

// class Bottom extends StatefulWidget {
//   final Widget? child;
//   const Bottom({super.key, required this.child});

//   @override
//   State<Bottom> createState() => _BottomState();
// }

// int currentPage = 0;

// class _BottomState extends State<Bottom> {
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<KStates>(builder: (context, state, childs) {
//       AudioPlayer _player = state.player;
//       int cs = 0;
//       return Scaffold(
//         body: SlidingUpPanel(
//           color: Color.fromARGB(255, 57, 42, 88),
//           panel: "Panel".text.make(),
//           collapsed: state.isLoaded
//               ? StreamBuilder(
//                   stream: _player.positionStream,
//                   builder: (context, snapshot1) {
//                     try {
//                       cs = _player.sequenceState!.currentIndex;
//                     } catch (e) {
//                       print(e);
//                     }

//                     // getOnlineInfo(playing);

//                     final Duration duration = state.isLoaded ? _player.position : const Duration(seconds: 0);
//                     return InkWell(
//                       onTap: () async {
//                         await VxBottomSheet.bottomSheetView(context,
//                             child: Play(
//                               player: _player,
//                               isOnline: "${state.tags[_player.sequenceState!.currentIndex]['url']}".contains('http'),
//                               onLinePlaylist: false,
//                               onlineSongData: [],
//                               play: false,
//                               shuffle: false,
//                               state: state,
//                               index: _player.sequenceState!.currentIndex,
//                             ),
//                             maxHeight: 1,
//                             minHeight: 1);
//                       },
//                       child: Container(
//                         height: double.maxFinite,
//                         child: Column(
//                           children: [
//                             Row(
//                               children: [
//                                 state.tags.isNotEmpty
//                                     ? ClipRRect(
//                                         borderRadius: BorderRadius.circular(15),
//                                         child: state.isLoaded
//                                             ? state.tags[cs]['image'].runtimeType != String
//                                                 ? Image.memory(
//                                                     state.tags[cs]['image'],
//                                                     height: 60,
//                                                     width: 60,
//                                                     fit: BoxFit.cover,
//                                                   )
//                                                 : Image.network(
//                                                     state.tags[cs]['image'],
//                                                     height: 60,
//                                                     width: 60,
//                                                     fit: BoxFit.cover,
//                                                   )
//                                             : Image.asset(
//                                                 'assets/tune.png',
//                                                 height: 60,
//                                                 width: 60,
//                                                 fit: BoxFit.cover,
//                                               ),
//                                       )
//                                     : ClipRRect(
//                                         borderRadius: BorderRadius.circular(15),
//                                         child: Image.asset(
//                                           'assets/tune.png',
//                                           height: 60,
//                                           width: 60,
//                                           fit: BoxFit.cover,
//                                         ),
//                                       ),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     state.isLoaded
//                                         ? Text(
//                                             state.tags[cs]['title'],
//                                             maxLines: 1,
//                                           )
//                                         : const Text(
//                                             "Nothing playing",
//                                             style: TextStyle(
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                     state.isLoaded
//                                         ? Text(
//                                             state.tags[cs]['artist'],
//                                             maxLines: 2,
//                                           )
//                                         : ''.text.make(),
//                                   ],
//                                 ).px8().py4().box.width(context.screenWidth * 0.5).make(),
//                                 const Spacer(),
//                                 state.isLoaded
//                                     ? IconButton(
//                                         onPressed: () {
//                                           if (_player.playing) {
//                                             setState(() {
//                                               _player.pause();
//                                             });
//                                           } else {
//                                             setState(() {
//                                               _player.play();
//                                             });
//                                           }
//                                           cs = _player.sequenceState!.currentIndex;
//                                         },
//                                         icon: Icon(
//                                           _player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
//                                           size: 30,
//                                           color: Colors.white,
//                                         ))
//                                     : IconButton(onPressed: () {}, icon: Icon(Icons.replay)),
//                                 state.isLoaded
//                                     ? IconButton(
//                                         onPressed: () async {
//                                           _player.hasNext ? await _player.seekToNext() : null;
//                                           cs = _player.sequenceState!.currentIndex;
//                                           _player.play();

//                                           setState(() {});
//                                         },
//                                         icon: Icon(
//                                           Icons.fast_forward_rounded,
//                                           color: _player.hasNext ? Colors.white : Colors.grey.shade600,
//                                           size: 20,
//                                         ))
//                                     : "".text.make(),
//                               ],
//                             ).px8().py8(),
//                             state.isLoaded
//                                 ? StreamBuilder(
//                                     stream: _player.bufferedPositionStream,
//                                     builder: (context, snapshot2) {
//                                       // print();
//                                       final Duration bufferedDuration = state.isLoaded ? _player.bufferedPosition : const Duration(seconds: 0);
//                                       return ProgressBar(
//                                         timeLabelType: TimeLabelType.totalTime,
//                                         progress: duration,
//                                         total: _player.duration ?? const Duration(seconds: 0),
//                                         buffered: bufferedDuration,
//                                         timeLabelPadding: 0,
//                                         thumbCanPaintOutsideBar: false,
//                                         thumbRadius: 1,
//                                         timeLabelTextStyle: const TextStyle(fontSize: 0, color: Colors.white),
//                                         barCapShape: BarCapShape.square,
//                                         barHeight: 2,
//                                         thumbGlowRadius: 2,
//                                         baseBarColor: Colors.transparent,
//                                         bufferedBarColor: Colors.transparent,
//                                         thumbColor: Colors.deepPurpleAccent.shade700,
//                                         onSeek: state.isLoaded
//                                             ? (duration) async {
//                                                 await _player.seek(duration);
//                                               }
//                                             : null,
//                                       );
//                                     })
//                                 : Row(),
//                             // state.isLoaded
//                             //     ? LinearProgressIndicator(
//                             //         minHeight: 2,
//                             //         value: _player.position.inSeconds / _player.duration!.inSeconds,
//                             //         backgroundColor: Colors.transparent,
//                             //       )
//                             //     : Row(),
//                           ],
//                         ),
//                       ),
//                     ).expand();
//                   })
//               : Container(height: 50, width: 50, color: Colors.red),
//           body: widget.child,
//           maxHeight: context.screenHeight,
//           minHeight: 55,
//         ),
//         bottomNavigationBar: Container(
//           height: state.isLoaded ? 165 : 90,
//           width: 100,
//           child: NavigationBar(
//             backgroundColor: const Color.fromARGB(255, 20, 15, 30),
//             elevation: 0,
//             destinations: [
//               const NavigationDestination(icon: Icon(EvaIcons.music), label: 'For you').px(2.5),
//               const NavigationDestination(icon: Icon(EvaIcons.search), label: 'Search').px(2.5),
//               const NavigationDestination(icon: Icon(EvaIcons.list), label: 'Library').px(2.5),
//               const NavigationDestination(icon: Icon(Icons.settings), label: 'Settings').px(2.5),
//             ],
//             indicatorColor: Colors.deepPurple.shade400,
//             selectedIndex: currentPage,
//             onDestinationSelected: (value) {
//               // Provider.of<ThemeModal>(context, listen: false).setCoin(generalBox.getAt(1));
//               setState(() {
//                 currentPage = value;
//                 Provider.of<KStates>(context, listen: false).setCP(value);
//                 print(state.currentPage);
//               });
//             },
//           ),
//         ),
//       );
//     });
//   }
// }
