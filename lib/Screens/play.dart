import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:blur/blur.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter/material.dart';

import '../Helpers/lyrics.dart';
import '../Services/audiohandler.dart';
import '../Services/classes.dart';
import 'lyric.dart';

class Play extends StatefulWidget {
  final bool isOnline;
  final AudioPlayer player;
  final bool onLinePlaylist;
  final List onlineSongData;
  final bool play;
  final bool shuffle;
  final int index;
  final KStates state;
  const Play({super.key, required this.player, required this.isOnline, required this.onLinePlaylist, required this.onlineSongData, required this.play, required this.shuffle, required this.state, required this.index});

  @override
  State<Play> createState() => _PlayState();
}

bool loaded = false;
// double volume = 0.5;
Map musicTag = {};
// Metadata album = const Metadata();
int playing = 0;
final audioHandler = GetIt.instance<AudioPlayerHandler>();

class _PlayState extends State<Play> {
  // var generalBox = Hive.box('general');
  LoopMode lm = LoopMode.all;

  bool showLyrics = false;
  bool downloadedLyrics = false;

  void loadMusic() async {
    // audioHandler.;
    // try {
    audioHandler.stop();

    await audioHandler.addQueueItems(
      !"${widget.state.tags[0]['url']}".contains("http")
          ? List.generate(widget.state.tags.length, (index) {
              try {
                // String uint8ListTob64(Uint8List uint8list) {
                //   String base64String = base64Encode(uint8list);
                //   String header = "data:image/png;base64,";
                //   return header + base64String;
                // }

                return MediaItem(
                    id: widget.state.tags[index]['url'],
                    title: widget.state.tags[index]['title'],
                    artist: widget.state.tags[index]['artist'],
                    artUri: Uri.file("/storage/emulated/0/Kylae/${widget.state.tags[index]['title']}.jpg", windows: false),
                    extras: {'url': "${widget.state.tags[index]['url']}"}
                    // duration: Duration(
                    //   seconds: int.parse(
                    //     widget.state.tags[index]['duration'],
                    //   ),
                    // ),
                    );
              } catch (e) {
                print("error for ${widget.state.tags[index]['title']}");
                print("error for ${e}");
                return MediaItem(id: widget.state.tags[index]['url'], title: widget.state.tags[index]['title'], artist: widget.state.tags[index]['artist'], extras: {'url': "${widget.state.tags[index]['url']}"}
                    // duration: Duration(
                    //   seconds: int.parse(
                    //     widget.state.tags[index]['duration'],
                    //   ),
                    // ),
                    );
              }
            })
          : List.generate(
              widget.state.tags.length,
              (index) => MediaItem(
                  id: widget.state.tags[index]['url'],
                  title: widget.state.tags[index]['title'],
                  artist: widget.state.tags[index]['artist'],
                  artUri: Uri.parse(widget.state.tags[index]['image']),
                  duration: Duration(
                    seconds: int.parse(
                      widget.state.tags[index]['duration'],
                    ),
                  ),
                  extras: {'url': "${widget.state.tags[index]['url']}"}),
            ),
    );

    // } catch (e) {
    //   print(e);
    // }
    // print("Lists ${audioHandler.sequence!.toList()[0].tag}");
    loaded = false;
    try {
      setState(() {
        loaded = true;
        playing = widget.index;
      });
    } catch (e) {
      loaded = true;
    }
    audioHandler.setShuffleMode(widget.shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
    audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
    audioHandler.play();
  }

  void loadPeriod() {
    loaded = false;
    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        loaded = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    widget.play ? loadMusic() : loadPeriod();
  }

  final PanelController _pageController = PanelController();

  int page = 0;

  Stream<Duration> get _bufferedPositionStream => audioHandler.playbackState.map((state) => state.bufferedPosition).distinct();
  Stream<Duration> get _positionStream => audioHandler.playbackState.map((state) => state.updatePosition).distinct();
  Stream<Duration?> get _durationStream => audioHandler.mediaItem.map((item) => item?.duration).distinct();

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      direction: DismissDirection.down,
      background: const ColoredBox(color: Colors.transparent),
      key: const Key('playScreen'),
      onDismissed: (direction) {
        Navigator.pop(context);
      },
      child: SlidingUpPanel(
        renderPanelSheet: false,
        color: const Color.fromARGB(255, 17, 11, 34),
        controller: _pageController,
        maxHeight: context.screenHeight * 0.5,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        parallaxEnabled: true,
        minHeight: 120,
        panelBuilder: (sc) {
          return Stack(
            children: [
              const Blur(
                blur: 50,
                blurColor: Colors.transparent,
                child: SizedBox(
                  height: double.maxFinite,
                  width: double.maxFinite,
                ),
              ),
              StreamBuilder(
                  stream: audioHandler.queue,
                  builder: (context, s) {
                    return ListView.builder(
                        controller: sc,
                        itemCount: widget.state.tags.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return SizedBox(height: 120, child: "${widget.state.tags.length} Songs".text.scale(1.2).semiBold.makeCentered().py12());
                          } else {
                            try {
                              // print(audioHandler.shuffleIndices);
                              // print(audioHandler.sequence);
                              // int qIndex = audioHandler.sequence!.toList().indexWhere((element) {
                              //   // print(element.tag);
                              //   // print(element.shuffleIndices);
                              //   // print(element.tag['title']);
                              //   return element.tag['title'] == widget.state.tags[playing]['title'];
                              // });
                              int c = s.data!.indexWhere((element) {
                                return element.title == widget.state.tags[index - 1]['title'];
                              });
                              return ListTile(
                                onTap: () async {
                                  await audioHandler.skipToQueueItem(index - 1);
                                  audioHandler.play();
                                  setState(() {});
                                },
                                leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: "${widget.state.tags[playing]['url']}".contains('http')
                                        ? Image.network(widget.state.tags[c]['image'], height: 50, width: 50, fit: BoxFit.cover)
                                        : Image.memory(widget.state.tags[c]['image'], height: 50, width: 50, fit: BoxFit.cover)),
                                title: Text(widget.state.tags[c]['title']),
                                subtitle: Text(widget.state.tags[c]['artist']),
                                trailing: playing == c ? const Icon(Icons.bar_chart_rounded) : null,
                              );
                            } catch (e) {
                              return "Error $e".text.make();
                            }
                          }
                        });
                  }),
            ],
          );
        },
        collapsed: Container(
          height: 120,
          width: context.screenWidth,
          decoration: const BoxDecoration(color: Color.fromARGB(255, 22, 21, 22)),
          child: StreamBuilder(
              stream: audioHandler.queueState,
              builder: (context, s) {
                int c = 0;
                try {
                  c = s.data!.queueIndex ?? 0;
                } catch (e) {
                  print(e);
                }
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    !"${widget.state.tags[c]['url']}".contains('http')
                        ? Image.memory(
                            widget.state.tags[c]['image'],
                            height: context.screenHeight,
                            width: context.screenWidth,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            cacheKey: widget.state.tags[c]['image'],
                            key: Key(widget.state.tags[c]['image']),
                            imageUrl: widget.state.tags[c]['image'],
                            height: context.screenHeight,
                            width: context.screenWidth,
                            fit: BoxFit.cover,
                          ),
                    const Blur(
                      blur: 300,
                      blurColor: Colors.transparent,
                      child: SizedBox(
                        height: double.maxFinite,
                        width: double.maxFinite,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22.0),
                      child: Row(
                        verticalDirection: VerticalDirection.up,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              _pageController.open();
                              //TODO
                              // VxBottomSheet.bottomSheetView(context, child: "Check lyrics".text.make().box.height(250).width(250).make());
                            },
                            child: SizedBox(
                              height: 60,
                              width: context.screenWidth * 0.2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [const Icon(FeatherIcons.list), "Queue".text.scale(1.2).semiBold.makeCentered()],
                              ),
                            ),
                          ),
                          "|".text.scale(2.4).semiBold.makeCentered(),
                          InkWell(
                            onTap: () {
                              VxBottomSheet.bottomSheetView(
                                context,
                                backgroundColor: Colors.transparent,
                                minHeight: .8,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    height: context.screenHeight * 0.8,
                                    width: context.screenWidth,
                                    child: DefaultTabController(
                                      length: 2,
                                      child: Scaffold(
                                        backgroundColor: Colors.transparent,
                                        appBar: AppBar(
                                          automaticallyImplyLeading: false,
                                          title: const TabBar(
                                            tabs: [
                                              Tab(
                                                text: "Lyrics",
                                              ),
                                              Tab(text: "Synced-lyrics"),
                                            ],
                                          ),
                                        ),
                                        body: TabBarView(
                                          children: [
                                            SyncLyrics(
                                              title: widget.state.tags[playing]['title'],
                                              artist: widget.state.tags[playing]['artist'],
                                              player: widget.player,
                                            ),
                                            SizedBox(
                                              height: context.screenHeight * 0.8,
                                              child: ListView(
                                                children: [
                                                  "${widget.state.tags[playing]['lyrics']}".replaceAll(RegExp(r'\n\n'), '\n🎵\n').text.scale(1.3).semiBold.make(),
                                                ],
                                              ).px12(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                isSafeAreaFromBottom: true,
                              );
                            },
                            child: SizedBox(
                              height: 60,
                              width: context.screenWidth * 0.2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [const Icon(FeatherIcons.feather), "Lyrics".text.scale(1.2).semiBold.makeCentered()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
        ),
        footer: InkWell(
            onTap: () {
              _pageController.close();
            },
            child: Container(
              height: 160,
              // padding: EdgeInsets.only(bottom: 40),
              alignment: Alignment.center,
              width: context.screenWidth,
              color: Colors.grey.shade900.withOpacity(.0),
              child: const Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Blur(
                    blur: 100,
                    blurColor: Colors.transparent,
                    child: SizedBox(
                      height: 120,
                      width: double.maxFinite,
                    ),
                  ),
                  Center(child: Icon(Icons.keyboard_arrow_up, size: 30)),
                ],
              ),
            )),
        body: SizedBox(
          height: context.screenHeight,
          width: context.screenWidth,
          child: Stack(
            children: [
              // AppBar(),
              !"${widget.state.tags[playing]['url']}".contains('http')
                  ? StreamBuilder(
                      stream: audioHandler.queueState,
                      builder: (context, s) {
                        int c = 0;
                        try {
                          c = s.data!.queueIndex ?? 0;
                          loaded ? playing = c : null;
                        } catch (e) {
                          print(e);
                        }
                        return Image.memory(
                          widget.state.tags[c]['image'],
                          height: double.maxFinite,
                          width: double.maxFinite,
                          fit: BoxFit.cover,
                        );
                      })
                  : StreamBuilder(
                      stream: audioHandler.queueState,
                      builder: (context, s) {
                        int c = 0;
                        try {
                          c = s.data!.queueIndex ?? 0;
                        } catch (e) {
                          print(e);
                        }
                        return CachedNetworkImage(
                          cacheKey: widget.state.tags[c]['image'],
                          key: Key(widget.state.tags[c]['image']),
                          imageUrl: widget.state.tags[c]['image'],
                          height: double.maxFinite,
                          width: double.maxFinite,
                          fit: BoxFit.cover,
                        );
                      }),
              const Blur(
                blur: 100,
                blurColor: Colors.transparent,
                child: SizedBox(
                  height: double.maxFinite,
                  width: double.maxFinite,
                ),
              ),
              SizedBox(
                height: double.maxFinite,
                width: double.maxFinite,
                // padding: const EdgeInsets.only(top: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    !"${widget.state.tags[playing]['url']}".contains('http')
                        ? InkWell(
                            onTap: () {
                              // Navigator.push(context, MaterialPageRoute(builder: (context) {
                              //   return SyncLyrics(
                              //     title: widget.state.tags[playing]['title'],
                              //     artist: widget.state.tags[playing]['artist'],
                              //     player: audioHandler,
                              //   );
                              // }));
                            },
                            child: StreamBuilder(
                                stream: audioHandler.queueState,
                                builder: (context, s) {
                                  int c = 0;
                                  try {
                                    c = s.data!.queueIndex ?? 0;
                                  } catch (e) {
                                    print(e);
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.memory(
                                      widget.state.tags[c]['image'],
                                      height: context.screenWidth * 0.8,
                                      width: context.screenWidth * 0.8,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }))
                        : StreamBuilder(
                            stream: audioHandler.queueState,
                            builder: (context, s) {
                              int c = 0;
                              try {
                                c = s.data!.queueIndex ?? 0;
                              } catch (e) {
                                print(e);
                              }
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  cacheKey: widget.state.tags[c]['image'],
                                  key: Key(widget.state.tags[c]['image']),
                                  imageUrl: widget.state.tags[c]['image'],
                                  height: context.screenWidth * 0.8,
                                  width: context.screenWidth * 0.8,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }),
                    const SizedBox(
                      height: 15,
                    ),
                    StreamBuilder(
                        stream: audioHandler.queueState,
                        builder: (context, s) {
                          int c = 0;
                          try {
                            c = s.data!.queueIndex ?? 0;
                          } catch (e) {
                            print(e);
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              !"${widget.state.tags[c]['url']}".contains('http') ? "${widget.state.tags[c]['title']}".text.scale(1.8).center.semiBold.make() : "${widget.state.tags[c]['title']}".text.scale(1.8).semiBold.center.make(),
                              !"${widget.state.tags[c]['url']}".contains('http') ? "${widget.state.tags[c]['artist']}".text.center.make() : "${widget.state.tags[c]['artist']}".text.center.make(),
                            ],
                          );
                        }),

                    StreamBuilder<Duration?>(
                        stream: _durationStream,
                        builder: (context, snapshot) {
                          Duration? position = snapshot.data;
                          return StreamBuilder<Duration?>(
                              stream: _bufferedPositionStream,
                              builder: (context, snapshot1) {
                                Duration? bufferedPosition = snapshot1.data;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  child: SizedBox(
                                    height: 30,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: ProgressBar(
                                        barHeight: 6,
                                        timeLabelType: TimeLabelType.totalTime,
                                        thumbRadius: 4,
                                        progress: loaded ? position ?? Duration.zero : const Duration(seconds: 0),
                                        total: snapshot.data ?? const Duration(seconds: 0),
                                        buffered: loaded ? bufferedPosition : const Duration(seconds: 0),
                                        timeLabelPadding: 2,
                                        timeLabelTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
                                        progressBarColor: Colors.grey.shade100,
                                        baseBarColor: Colors.grey.shade700,
                                        bufferedBarColor: widget.state.tags[playing]['url'].contains('http') ? Colors.grey[550] : Colors.transparent,
                                        thumbColor: Colors.white,
                                        onSeek: loaded
                                            ? (duration) async {
                                                await audioHandler.seek(duration);
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              });
                        }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        StreamBuilder<Duration>(
                            stream: _positionStream,
                            builder: (context, s) {
                              int position = 0;
                              try {
                                position = s.data!.inSeconds ?? 0;
                              } catch (e) {
                                print(e);
                              }
                              return IconButton(
                                onPressed: loaded
                                    ? () async {
                                        if (position >= 10) {
                                          await audioHandler.seek(const Duration(seconds: 0));
                                        } else {
                                          await audioHandler.skipToPrevious();
                                        }
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.fast_rewind_rounded,
                                  size: 35,
                                ),
                              );
                            }),
                        StreamBuilder(
                            stream: audioHandler.playbackState,
                            builder: (context, s) {
                              bool p = false;
                              try {
                                p = s.data!.playing;
                              } catch (e) {
                                print(e);
                              }
                              return SizedBox(
                                height: 90,
                                width: 90,
                                child: loaded
                                    ? IconButton(
                                        onPressed: loaded
                                            ? () {
                                                if (p) {
                                                  audioHandler.pause();
                                                } else {
                                                  audioHandler.play();
                                                }
                                              }
                                            : null,
                                        icon: Icon(
                                          p ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 70,
                                        ))
                                    : const CircularProgressIndicator().box.height(60).make(),
                              );
                            }),
                        IconButton(
                            onPressed: loaded
                                ? () async {
                                    await audioHandler.skipToNext();
                                  }
                                : null,
                            icon: const Icon(
                              Icons.fast_forward_rounded,
                              size: 35,
                            )),
                        const SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _repeatButton(context, lm),
                        // InkWell(
                        //   onTap: () {
                        //     setState(() {
                        //       showLyrics = !showLyrics;
                        //     });
                        //   },
                        //   child: "lyrics".text.scale(0.8).semiBold.color(!showLyrics ? Colors.white : Colors.grey.shade500).makeCentered().py2().px4(),
                        // ).box.color(showLyrics ? Colors.white : Colors.grey.shade500).roundedSM.make(),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              FeatherIcons.downloadCloud,
                              color: Colors.white,
                            ))
                      ],
                    ),
                    const SizedBox(height: 15),
                    // !showLyrics ? "Volume".text.scale(1.2).semiBold.makeCentered() : const SizedBox(),
                    // !showLyrics
                    //     ? Slider(
                    //         value: volume,
                    //         activeColor: Colors.white,
                    //         onChanged: (value) {
                    //           setState(() {
                    //             volume = value;
                    //           });
                    //           audioHandler.setVolume(volume);
                    //         }).px16()
                    //     : const SizedBox(
                    //         // height: 50,
                    //         ),
                    const SizedBox(
                      height: 125,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _repeatButton(BuildContext context, LoopMode loopMode) {
    const icons = [
      Icon(Icons.repeat),
      Icon(Icons.repeat, color: Colors.white),
      Icon(Icons.repeat_one, color: Colors.white),
    ];
    List cycleModes = [
      AudioServiceRepeatMode.none,
      AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.one,
    ];
    final index = 0;
    // print("IconD $index");
    return IconButton(
      icon: icons[index],
      onPressed: () {
        setState(() {
          if (cycleModes.indexOf(loopMode) != 2) {
            lm = cycleModes[cycleModes.indexOf(loopMode) + 1];
          } else {
            lm = cycleModes[0];
          }
          audioHandler.setRepeatMode(cycleModes[(cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
        });
      },
    );
  }

  // ignore: unused_element
  Widget _shuffleButton(BuildContext context, bool isEnabled) {
    return IconButton(
      icon: isEnabled ? const Icon(Icons.shuffle, color: Colors.white) : const Icon(Icons.shuffle),
      onPressed: () async {
        final enable = !isEnabled;
        if (enable) {
          await audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
        }
      },
    );
  }
}

class QueueState {
  static const QueueState empty = QueueState([], 0, [], AudioServiceRepeatMode.none);

  final List<MediaItem> queue;
  final int? queueIndex;
  final List<int>? shuffleIndices;
  final AudioServiceRepeatMode repeatMode;

  const QueueState(
    this.queue,
    this.queueIndex,
    this.shuffleIndices,
    this.repeatMode,
  );

  bool get hasPrevious => repeatMode != AudioServiceRepeatMode.none || (queueIndex ?? 0) > 0;
  bool get hasNext => repeatMode != AudioServiceRepeatMode.none || (queueIndex ?? 0) + 1 < queue.length;

  List<int> get indices => shuffleIndices ?? List.generate(queue.length, (i) => i);
}

abstract class AudioPlayerHandler implements AudioHandler {
  Stream<QueueState> get queueState;
  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;
}
