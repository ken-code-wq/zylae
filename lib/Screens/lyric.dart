import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_lyric/lyric_ui/ui_netease.dart';
import 'package:flutter_lyric/lyrics_model_builder.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:flutter_lyric/lyrics_reader_widget.dart';
import 'package:just_audio/just_audio.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:http/http.dart';
import 'package:zylae/Services/classes.dart';
import 'package:zylae/apis/spotify_api.dart';
import '../Helpers/lyrics.dart';

class SyncLyrics extends StatefulWidget {
  final String title;
  final String artist;
  final AudioPlayer player;
  const SyncLyrics({super.key, required this.title, required this.artist, required this.player});

  @override
  State<SyncLyrics> createState() => Sync_LyricsState();
}

bool sync_loaded = false;
List<LyricLine> ll = [];
Duration pos = Duration.zero;
ScrollController con = ScrollController();
final ItemScrollController itemScrollController = ItemScrollController();
final ScrollOffsetController scrollOffsetController = ScrollOffsetController();
final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
final ScrollOffsetListener scrollOffsetListener = ScrollOffsetListener.create();

class Sync_LyricsState extends State<SyncLyrics> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSL();
  }

  void getSL() async {
    ll.clear();
    sync_loaded = false;
    print("gtting id");

    final link1 = await Lyrics.getSpotifyID(widget.title, widget.artist);
    print("getting ly of $link1");

    final ul = Uri.parse('https://spotify-lyric-api-984e7b4face0.herokuapp.com/?trackid=$link1');
    final u = Uri.parse('https://spotify-lyric-api-984e7b4face0.herokuapp.com/?trackid=22skzmqfdWrjJylampe0kt');
    // final link = await Lyrics.getSpotifyLyricsFromId("${link1['lyrics']}");

    try {
      final res = await get(ul);
      Map body = jsonDecode(res.body) as Map;
      for (Map line in body['lines']) {
        // print((double.parse(line['timeTag'][1]) * 60) + (double.parse(line['timeTag'][3]) * 10) + (double.parse(line['timeTag'][4])) + (double.parse(line['timeTag'][6]) / 10) + (double.parse(line['timeTag'][7]) / 100));
        ll.add(LyricLine(timeTag: int.parse(line['startTimeMs']), words: line['words']));
      }
      setState(() {
        sync_loaded = true;
      });
    } catch (e) {
      print("error is $e");
    }
  }

  int cs = 0;

  @override
  Widget build(BuildContext context) {
    widget.player.positionStream.listen((event) {
      Duration posi = event;
      try {
        int index = ll.lastIndexWhere((element) => posi.inMilliseconds >= element.timeTag);
        print(posi);
        print(Duration(milliseconds: ll[index].timeTag));
        if (posi >= Duration(milliseconds: ll[index].timeTag) && index >= 4) {
          print(true);
          itemScrollController.jumpTo(index: index - 7);
        }

        // if (DateTime(1970, 0, 0, 0, 0, 0, lyric.timeTag).isAfter(DateTime(1970, 0, 0, 0, 0, 0, position.inMilliseconds))) {
        //   print(lyric.timeTag <= position.inMilliseconds);
        //   print(ll[w - 3].words);
        //   // itemScrollController.scrollTo(index: w - 3, duration: Duration(milliseconds: 300));
        //   itemScrollController.scrollTo(index: w - 3, duration: const Duration(milliseconds: 30));
        // } else {
        //   cs = w;
        // }index > 4 && DateTime(1970, 0, 0, 0, 0, 0, ll![index].timeTag).isAfter(DateTime(1970, 0, 0, 0, 0, 0, pos.inMilliseconds))
      } catch (e) {
        print("error is $e");
      }
      // for (LyricLine lyric in ll) {
      //   int w = ll.lastIndexWhere((element) {
      //     return Duration(milliseconds: element.timeTag) <= position;
      //   });

      // }
    });
    // Timer.periodic(Duration(seconds: 2), (timer) {
    //   itemScrollController.scrollTo(index: timer.tick - 3, duration: const Duration(milliseconds: 500), curve: Curves.fastOutSlowIn);
    // });
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
      child: Scaffold(
        extendBody: true,
        body: SizedBox(
          height: context.screenHeight,
          child: !sync_loaded && ll.isEmpty
              ? SizedBox(height: context.screenHeight, width: context.screenWidth, child: const CircularProgressIndicator().centered())
              : StreamBuilder<Duration>(
                  stream: widget.player.positionStream,
                  builder: (context, snapshot) {
                    Duration position = snapshot.data ?? const Duration(microseconds: 1);
                    pos = position;
                    final total = widget.player.duration;
                    int w = ll.lastIndexWhere((element) {
                      return Duration(milliseconds: element.timeTag) <= position;
                    });
                    // if (w != cs) {
                    // try {
                    //   if (w > 3 || w > ll.length - 4) {
                    //     // itemScrollController.scrollTo(index: w - 3, duration: Duration(milliseconds: 300));
                    //     cs = w;
                    //     itemScrollController.scrollTo(index: w - 3, duration: const Duration(milliseconds: 500), curve: Curves.fastOutSlowIn);
                    //   } else {
                    //     cs = w;
                    //   }
                    // } catch (e) {
                    //   print(e);
                    // }
                    // }
                    return ScrollablePositionedList.builder(
                      scrollDirection: Axis.vertical,
                      itemScrollController: itemScrollController,
                      scrollOffsetController: scrollOffsetController,
                      itemPositionsListener: itemPositionsListener,
                      scrollOffsetListener: scrollOffsetListener,
                      itemCount: ll.length,
                      itemBuilder: ((context, index) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          child: ListTile(
                            title: Text(
                              ll[index].words,
                              style: TextStyle(
                                color: position >= Duration(milliseconds: ll[index].timeTag) ? Colors.white : Colors.white.withOpacity(.5),
                                fontSize: position >= Duration(milliseconds: ll[index].timeTag) ? 22 : 18,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
        ),
        // body: ,
      ),
    );
  }
}
