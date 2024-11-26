/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:velocity_x/velocity_x.dart';

import '../Helpers/mediaitemconvertor.dart';
import '../Screens/play.dart';
import 'download_buttom.dart';
import 'image.dart';

class MiniPlayer extends StatefulWidget {
  static const MiniPlayer _instance = MiniPlayer._internal();

  factory MiniPlayer() {
    return _instance;
  }

  const MiniPlayer._internal();

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    // final double screenWidth = MediaQuery.of(context).size.width;
    // final double screenHeight = MediaQuery.of(context).size.height;
    // final bool rotated = screenHeight < screenWidth;
    return SafeArea(
      top: false,
      child: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          // if (snapshot.connectionState != ConnectionState.active) {
          //   return const SizedBox();
          // }
          final MediaItem? mediaItem = snapshot.data;
          // if (mediaItem == null) return const SizedBox();

          final List preferredMiniButtons = Hive.box('settings').get(
            'preferredMiniButtons',
            defaultValue: ['Like', 'Play/Pause', 'Next'],
          )?.toList() as List;

          final bool isLocal = mediaItem?.artUri?.toString().startsWith('file:') ?? false;

          return Dismissible(
            key: const Key('miniplayer'),
            direction: DismissDirection.vertical,
            confirmDismiss: (DismissDirection direction) {
              if (mediaItem != null) {
                if (direction == DismissDirection.down) {
                  audioHandler.stop();
                } else {
                  Navigator.pushNamed(context, '/player');
                }
              }
              return Future.value(false);
            },
            child: Dismissible(
              key: Key(mediaItem?.id ?? 'nothingPlaying'),
              confirmDismiss: (DismissDirection direction) {
                if (mediaItem != null) {
                  if (direction == DismissDirection.startToEnd) {
                    audioHandler.skipToPrevious();
                  } else {
                    audioHandler.skipToNext();
                  }
                }
                return Future.value(false);
              },
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 2.0,
                  vertical: 1.0,
                ),
                elevation: 0,
                child: SizedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      miniplayerTile(
                        context: context,
                        preferredMiniButtons: preferredMiniButtons,
                        // useDense: true,
                        title: mediaItem?.title ?? '',
                        subtitle: mediaItem?.artist ?? '',
                        imagePath: (isLocal ? mediaItem?.artUri?.toFilePath() : mediaItem?.artUri?.toString()) ?? '',
                        isLocalImage: isLocal,
                        isDummy: mediaItem == null,
                      ),
                      positionSlider(
                        mediaItem?.duration?.inSeconds.toDouble(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ListTile miniplayerTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required List preferredMiniButtons,
    bool useDense = false,
    bool isLocalImage = false,
    bool isDummy = false,
  }) {
    return ListTile(
      dense: useDense,
      onTap: isDummy
          ? null
          : () {
              Navigator.pushNamed(context, '/player');
            },
      title: Text(
        isDummy ? 'Now Playing' : title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isDummy ? 'Unknown' : subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Hero(
        tag: 'currentArtwork',
        child: imageCard(
          elevation: 8,
          boxDimension: useDense ? 40.0 : 50.0,
          localImage: isLocalImage,
          imageUrl: isLocalImage ? imagePath : imagePath,
        ),
      ),
      trailing: isDummy
          ? null
          : ControlButtons(
              audioHandler,
              miniplayer: true,
              buttons: isLocalImage ? ['Like', 'Play/Pause', 'Next'] : preferredMiniButtons,
            ),
    );
  }

  StreamBuilder<Duration> positionSlider(double? maxDuration) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data;
        return ((position?.inSeconds.toDouble() ?? 0) < 0.0 || ((position?.inSeconds.toDouble() ?? 0) > (maxDuration ?? 180.0)))
            ? const SizedBox()
            : SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).colorScheme.secondary,
                  inactiveTrackColor: Colors.transparent,
                  trackHeight: 0.5,
                  thumbColor: Theme.of(context).colorScheme.secondary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 1.0,
                  ),
                  overlayColor: Colors.transparent,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 2.0,
                  ),
                ),
                child: Center(
                  child: Slider(
                    inactiveColor: Colors.transparent,
                    // activeColor: Colors.white,
                    value: position?.inSeconds.toDouble() ?? 0,
                    max: maxDuration ?? 180.0,
                    onChanged: (newPosition) {
                      audioHandler.seek(
                        Duration(
                          seconds: newPosition.round(),
                        ),
                      );
                    },
                  ),
                ),
              );
      },
    );
  }
}

class ControlButtons extends StatelessWidget {
  final AudioPlayerHandler audioHandler;
  final bool shuffle;
  final bool miniplayer;
  final List buttons;
  final Color? dominantColor;

  const ControlButtons(
    this.audioHandler, {
    this.shuffle = false,
    this.miniplayer = false,
    this.buttons = const ['Previous', 'Play/Pause', 'Next'],
    this.dominantColor,
  });

  @override
  Widget build(BuildContext context) {
    final MediaItem mediaItem = audioHandler.mediaItem.value!;
    final bool online = mediaItem.extras!['url'].toString().startsWith('http');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: buttons.map((e) {
        switch (e) {
          case 'Like':
            return !online ? const SizedBox() : "Like".text.make();
          // LikeButton(
          //     mediaItem: mediaItem,
          //     size: 22.0,
          //   );
          case 'Previous':
            return StreamBuilder<QueueState>(
              stream: audioHandler.queueState,
              builder: (context, snapshot) {
                final queueState = snapshot.data;
                return IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: miniplayer ? 24.0 : 45.0,
                  color: dominantColor ?? Theme.of(context).iconTheme.color,
                  onPressed: queueState?.hasPrevious ?? true ? audioHandler.skipToPrevious : null,
                );
              },
            );
          case 'Play/Pause':
            return SizedBox(
              height: miniplayer ? 40.0 : 65.0,
              width: miniplayer ? 40.0 : 65.0,
              child: StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playbackState = snapshot.data;
                  final processingState = playbackState?.processingState;
                  final playing = playbackState?.playing ?? true;
                  return Stack(
                    children: [
                      if (processingState == AudioProcessingState.loading || processingState == AudioProcessingState.buffering)
                        Center(
                          child: SizedBox(
                            height: miniplayer ? 40.0 : 65.0,
                            width: miniplayer ? 40.0 : 65.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).iconTheme.color!,
                              ),
                            ),
                          ),
                        ),
                      if (miniplayer)
                        Center(
                          child: playing
                              ? IconButton(
                                  onPressed: audioHandler.pause,
                                  icon: const Icon(
                                    Icons.pause_rounded,
                                  ),
                                  color: Theme.of(context).iconTheme.color,
                                )
                              : IconButton(
                                  onPressed: audioHandler.play,
                                  icon: const Icon(
                                    Icons.play_arrow_rounded,
                                  ),
                                  color: Theme.of(context).iconTheme.color,
                                ),
                        )
                      else
                        Center(
                          child: SizedBox(
                            height: 59,
                            width: 59,
                            child: Center(
                              child: playing
                                  ? FloatingActionButton(
                                      elevation: 10,
                                      backgroundColor: Colors.white,
                                      onPressed: audioHandler.pause,
                                      child: const Icon(
                                        Icons.pause_rounded,
                                        size: 40.0,
                                        color: Colors.black,
                                      ),
                                    )
                                  : FloatingActionButton(
                                      elevation: 10,
                                      backgroundColor: Colors.white,
                                      onPressed: audioHandler.play,
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 40.0,
                                        color: Colors.black,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          case 'Next':
            return StreamBuilder<QueueState>(
              stream: audioHandler.queueState,
              builder: (context, snapshot) {
                final queueState = snapshot.data;
                return IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: miniplayer ? 24.0 : 45.0,
                  color: dominantColor ?? Theme.of(context).iconTheme.color,
                  onPressed: queueState?.hasNext ?? true ? audioHandler.skipToNext : null,
                );
              },
            );
          case 'Download':
            return !online
                ? const SizedBox()
                : DownloadButton(
                    size: 20.0,
                    icon: 'download',
                    data: MediaItemConverter.mediaItemToMap(mediaItem),
                  );
          default:
            break;
        }
        return const SizedBox();
      }).toList(),
    );
  }
}
