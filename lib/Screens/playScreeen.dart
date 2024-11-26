// // ignore_for_file: file_names

// import 'package:blur/blur.dart';
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:provider/provider.dart';
// import 'package:velocity_x/velocity_x.dart';
// import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
// import 'package:just_audio/just_audio.dart';

// import '../Services/classes.dart';
// import '../Services/download.dart';

// // class PlayScreen extends StatefulWidget {
// //   final String musicUrl;

// //   final String id;
// //   const PlayScreen({super.key, required this.id, required this.musicUrl});

// //   @override
// //   State<PlayScreen> createState() => _PlayScreenState();
// // }

// // double sv = 0;
// // var generalBox = Hive.box('general');
// // bool finished = false;

// // class _PlayScreenState extends State<PlayScreen> {
// //   String preferredDownloadQuality = '320 kbps';
// //   late Download down;
// //   @override
// //   void initState() {
// //     super.initState();

// //     // loadMusic();
// //     down = Download(widget.id.toString());
// //     // loadMusic();
// //     down.addListener(() {
// //       if (mounted) {
// //         setState(() {});
// //       }
// //     });
// //   }

// //   Future<void> _waitUntilDone(String id) async {
// //     while (down.lastDownloadId != id) {
// //       await Future.delayed(const Duration(seconds: 1));
// //     }
// //     return;
// //   }

// //   void _download(var data) async {
// //     var box = generalBox.getAt(1);
// //     box.add(widget.id);
// //     print(box);
// //     try {
// //       down.prepareDownload(context, data);
// //       generalBox.putAt(1, box);
// //       await _waitUntilDone(widget.id);
// //       setState(() {
// //         finished = true;
// //       });
// //     } catch (e) {
// //       // print(e);
// //     }
// //   }

// //   // String thumbnailImgUrl = ""; // Insert your thumbnail URL
// //   bool loaded = false;
// //   bool playing = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     // loadMusic();
// //     return Consumer<KStates>(builder: (context, state, child) {
// //       // int? d = state.data.duration;
// //       return Container(
// //         child: Blur(
// //           blurColor: Colors.transparent,
// //           blur: 20,
// //           overlay: Column(
// //             children: [
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   IconButton(
// //                       onPressed: () {
// //                         state.panelController.close();
// //                       },
// //                       icon: const Icon(Icons.keyboard_arrow_down_rounded)),
// //                   IconButton(
// //                       onPressed: () {
// //                         // state.panelController.close();
// //                       },
// //                       icon: const Icon(Icons.favorite_border))
// //                 ],
// //               ).px12().py12(),
// //               const Spacer(),
// //               state.isPlaying
// //                   ? ClipRRect(
// //                       borderRadius: BorderRadius.circular(35),
// //                       child: Image.memory(
// //                         state.data.picture!,
// //                         fit: BoxFit.cover,
// //                         height: context.screenWidth * 0.8,
// //                         width: context.screenWidth * 0.8,
// //                       ),
// //                     )
// //                   : ClipRRect(
// //                       borderRadius: BorderRadius.circular(35),
// //                       child: Image.asset(
// //                         'assets/tune.png',
// //                         fit: BoxFit.cover,
// //                         height: context.screenWidth * 0.8,
// //                         width: context.screenWidth * 0.8,
// //                       ),
// //                     ),
// //               const Spacer(),
// //               Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   state.isPlaying ? "${state.data.title}".text.scale(1.8).semiBold.make() : "Nothing playing".text.scale(2).semiBold.make(),
// //                   state.isPlaying ? "${state.data.artist}".text.make() : ''.text.make(),
// //                 ],
// //               ),
// //               Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 8),
// //                 child: StreamBuilder(
// //                     stream: state.player.positionStream,
// //                     builder: (context, snapshot1) {
// //                       final Duration duration = loaded ? snapshot1.data as Duration : const Duration(seconds: 0);
// //                       return StreamBuilder(
// //                           stream: state.player.bufferedPositionStream,
// //                           builder: (context, snapshot2) {
// //                             final Duration bufferedDuration = loaded ? snapshot2.data as Duration : const Duration(seconds: 0);
// //                             return SizedBox(
// //                               height: 30,
// //                               child: Padding(
// //                                 padding: const EdgeInsets.symmetric(horizontal: 16),
// //                                 child: ProgressBar(
// //                                   progress: duration,
// //                                   total: state.player.duration ?? const Duration(seconds: 0),
// //                                   buffered: bufferedDuration,
// //                                   timeLabelPadding: 3,
// //                                   timeLabelTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
// //                                   progressBarColor: Colors.deepPurpleAccent,
// //                                   baseBarColor: Colors.grey[200],
// //                                   bufferedBarColor: Colors.grey[350],
// //                                   thumbColor: Colors.deepPurpleAccent,
// //                                   onSeek: loaded
// //                                       ? (duration) async {
// //                                           await state.player.seek(duration);
// //                                         }
// //                                       : null,
// //                                 ),
// //                               ),
// //                             );
// //                           });
// //                     }),
// //               ),
// //               const SizedBox(
// //                 height: 8,
// //               ),
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                 children: [
// //                   const SizedBox(
// //                     width: 10,
// //                   ),
// //                   IconButton(
// //                       onPressed: loaded
// //                           ? () async {
// //                               if (state.player.position.inSeconds >= 10) {
// //                                 await state.player.seek(Duration(seconds: state.player.position.inSeconds - 10));
// //                               } else {
// //                                 await state.player.seek(const Duration(seconds: 0));
// //                               }
// //                             }
// //                           : null,
// //                       icon: const Icon(Icons.fast_rewind_rounded)),
// //                   Container(
// //                     height: 50,
// //                     width: 50,
// //                     decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
// //                     child: IconButton(
// //                         onPressed: loaded
// //                             ? () {
// //                                 if (state.player.playing) {
// //                                   Provider.of<KStates>(context, listen: false).pauseMusic();
// //                                 } else {
// //                                   Provider.of<KStates>(context, listen: false).playMusic();
// //                                 }
// //                               }
// //                             : null,
// //                         icon: Icon(
// //                           playing ? Icons.pause : Icons.play_arrow,
// //                           color: Colors.white,
// //                         )),
// //                   ),
// //                   IconButton(
// //                       onPressed: loaded
// //                           ? () async {
// //                               if (state.player.position.inSeconds + 10 <= state.player.duration!.inSeconds) {
// //                                 await state.player.seek(Duration(seconds: state.player.position.inSeconds + 10));
// //                               } else {
// //                                 await state.player.seek(const Duration(seconds: 0));
// //                               }
// //                             }
// //                           : null,
// //                       icon: const Icon(Icons.fast_forward_rounded)),
// //                   const SizedBox(
// //                     width: 10,
// //                   ),
// //                 ],
// //               ),
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                 children: [
// //                   IconButton(
// //                       onPressed: () {},
// //                       icon: const Icon(
// //                         Icons.keyboard_double_arrow_left_rounded,
// //                         size: 50,
// //                       )),
// //                   IconButton(
// //                       onPressed: () {
// //                         !finished ? _download(state.apiData) : null;
// //                       },
// //                       icon: Icon(
// //                         finished ? Icons.play_circle_fill_rounded : Icons.arrow_downward_rounded,
// //                         size: 70,
// //                       )),
// //                   IconButton(
// //                       onPressed: () {},
// //                       icon: const Icon(
// //                         Icons.keyboard_double_arrow_right_rounded,
// //                         size: 50,
// //                       )),
// //                 ],
// //               ),
// //               LinearProgressIndicator(value: down.progress).px12(),
// //               const Spacer(),
// //               const Spacer(),
// //               const Spacer(),
// //             ],
// //           ),
// //           child: state.isPlaying
// //               ? Image.memory(
// //                   state.data.picture!,
// //                   fit: BoxFit.cover,
// //                   height: context.screenHeight,
// //                 )
// //               : Image.asset(
// //                   'assets/tune.png',
// //                   fit: BoxFit.cover,
// //                   height: context.screenHeight,
// //                 ),
// //         ),
// //       );
// //     });
// //   }
// // }

// class BottomPlayWidget extends StatefulWidget {
//   const BottomPlayWidget({super.key});

//   @override
//   State<BottomPlayWidget> createState() => _BottomPlayWidgetState();
// }

// class _BottomPlayWidgetState extends State<BottomPlayWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<KStates>(
//       builder: (context, state, child) => InkWell(
//         onTap: () {
//           state.panelController.open();
//         },
//         child: Container(
//           height: 75,
//           width: context.screenWidth,
//           child: Row(
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(6),
//                 child: !state.isPlaying
//                     ? Image.asset(
//                         'assets/tune.png',
//                         fit: BoxFit.cover,
//                         height: 60,
//                         width: 60,
//                       )
//                     : Image.memory(
//                         state.data.picture!,
//                         fit: BoxFit.cover,
//                         height: 60,
//                         width: 60,
//                       ),
//               ).px12(),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   state.isPlaying ? "${state.data.title}".text.ellipsis.maxLines(1).scale(1.3).semiBold.make().box.width(context.screenWidth - 180).make() : "Nothing playing".text.scale(1.8).semiBold.make(),
//                   state.isPlaying ? "${state.data.artist}".text.make() : ''.text.make(),
//                 ],
//               ),
//               const Spacer(),
//               IconButton(onPressed: () {}, icon: const Icon(Icons.download_rounded)).px16()
//             ],
//           ),
//         ).box.color(const Color.fromRGBO(35, 24, 52, 1)).make(),
//       ),
//     );
//   }
// }
