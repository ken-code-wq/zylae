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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:velocity_x/velocity_x.dart';

import '../Helpers/audio_query.dart';
import '../Helpers/custom_physics.dart';
import '../Services/play_service.dart';
import '../Widgets/search.dart';
import '../Widgets/snackbar.dart';

class DownloadedSongs extends StatefulWidget {
  final List<SongModel>? cachedSongs;
  final String? title;
  final int? playlistId;
  final bool showPlaylists;
  const DownloadedSongs({
    super.key,
    this.cachedSongs,
    this.title,
    this.playlistId,
    this.showPlaylists = false,
  });
  @override
  _DownloadedSongsState createState() => _DownloadedSongsState();
}

class _DownloadedSongsState extends State<DownloadedSongs> with TickerProviderStateMixin {
  List<SongModel> _songs = [];
  String? tempPath = Hive.box('settings').get('tempDirPath')?.toString();
  final Map<String, List<SongModel>> _albums = {};
  final Map<String, List<SongModel>> _artists = {};
  final Map<String, List<SongModel>> _genres = {};
  final Map<String, List<SongModel>> _folders = {};

  final List<String> _sortedAlbumKeysList = [];
  final List<String> _sortedArtistKeysList = [];
  final List<String> _sortedGenreKeysList = [];
  final List<String> _sortedFolderKeysList = [];
  // final List<String> _videos = [];

  bool added = false;
  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 1) as int;
  int orderValue = Hive.box('settings').get('orderValue', defaultValue: 1) as int;
  int albumSortValue = Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;
  List dirPaths = Hive.box('settings').get('searchPaths', defaultValue: []) as List;
  int minDuration = Hive.box('settings').get('minDuration', defaultValue: 10) as int;
  bool includeOrExclude = Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool;
  List includedExcludedPaths = Hive.box('settings').get('includedExcludedPaths', defaultValue: []) as List;
  TabController? _tcontroller;
  int _currentTabIndex = 0;
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  List<PlaylistModel> playlistDetails = [];

  final Map<int, SongSortType> songSortTypes = {
    0: SongSortType.DISPLAY_NAME,
    1: SongSortType.DATE_ADDED,
    2: SongSortType.ALBUM,
    3: SongSortType.ARTIST,
    4: SongSortType.DURATION,
    5: SongSortType.SIZE,
  };

  final Map<int, OrderType> songOrderTypes = {
    0: OrderType.ASC_OR_SMALLER,
    1: OrderType.DESC_OR_GREATER,
  };

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tcontroller!.dispose();
  }

  bool checkIncludedOrExcluded(SongModel song) {
    for (final path in includedExcludedPaths) {
      if (song.data.contains(path.toString())) return true;
    }
    return false;
  }

  Future<void> getData() async {
    try {
      //.root.info('Requesting permission to access local songs');
      await offlineAudioQuery.requestPermission();
      tempPath ??= (await getTemporaryDirectory()).path;
      if (Platform.isAndroid) {
        //.root.info('Getting local playlists');
        playlistDetails = await offlineAudioQuery.getPlaylists();
      }
      if (widget.cachedSongs == null) {
        //.root.info('Cache empty, calling audioQuery');
        final receivedSongs = await offlineAudioQuery.getSongs(
          sortType: songSortTypes[sortValue],
          orderType: songOrderTypes[orderValue],
        );
        //.root.info('Received ${receivedSongs.length} songs, filtering');
        _songs = receivedSongs
            .where(
              (i) => (i.duration ?? 60000) > 1000 * minDuration && (i.isMusic! || i.isPodcast! || i.isAudioBook!) && (includeOrExclude ? checkIncludedOrExcluded(i) : !checkIncludedOrExcluded(i)),
            )
            .toList();
      } else {
        //.root.info('Setting songs to cached songs');
        _songs = widget.cachedSongs!;
      }
      added = true;
      //.root.info('got ${_songs.length} songs');
      setState(() {});
      //.root.info('setting albums and artists');
      for (int i = 0; i < _songs.length; i++) {
        try {
          if (_albums.containsKey(_songs[i].album ?? 'Unknown')) {
            _albums[_songs[i].album ?? 'Unknown']!.add(_songs[i]);
          } else {
            _albums[_songs[i].album ?? 'Unknown'] = [_songs[i]];
            _sortedAlbumKeysList.add(_songs[i].album ?? 'Unknown');
          }

          if (_artists.containsKey(_songs[i].artist ?? 'Unknown')) {
            _artists[_songs[i].artist ?? 'Unknown']!.add(_songs[i]);
          } else {
            _artists[_songs[i].artist ?? 'Unknown'] = [_songs[i]];
            _sortedArtistKeysList.add(_songs[i].artist ?? 'Unknown');
          }

          if (_genres.containsKey(_songs[i].genre ?? 'Unknown')) {
            _genres[_songs[i].genre ?? 'Unknown']!.add(_songs[i]);
          } else {
            _genres[_songs[i].genre ?? 'Unknown'] = [_songs[i]];
            _sortedGenreKeysList.add(_songs[i].genre ?? 'Unknown');
          }

          final tempPath = _songs[i].data.split('/');
          tempPath.removeLast();
          final dirPath = tempPath.join('/');

          if (_folders.containsKey(dirPath)) {
            _folders[dirPath]!.add(_songs[i]);
          } else {
            _folders[dirPath] = [_songs[i]];
            _sortedFolderKeysList.add(dirPath);
          }
        } catch (e) {
          //.root.severe('Error in sorting songs', e);
        }
      }
      print(_songs);
      print('albums, artists, genre & folders set');
    } catch (e) {
      added = true;
    }
  }

  Future<void> sortSongs(int sortVal, int order) async {
    //.root.info('Sorting songs');
    switch (sortVal) {
      case 0:
        _songs.sort(
          (a, b) => a.displayName.compareTo(b.displayName),
        );
        break;
      case 1:
        _songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
        break;
      case 2:
        _songs.sort(
          (a, b) => a.album.toString().compareTo(b.album.toString()),
        );
        break;
      case 3:
        _songs.sort(
          (a, b) => a.artist.toString().compareTo(b.artist.toString()),
        );
        break;
      case 4:
        _songs.sort(
          (a, b) => a.duration.toString().compareTo(b.duration.toString()),
        );
        break;
      case 5:
        _songs.sort(
          (a, b) => a.size.toString().compareTo(b.size.toString()),
        );
        break;
      default:
        _songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
        break;
    }

    if (order == 1) {
      _songs = _songs.reversed.toList();
    }
    //.root.info('Done Sorting songs');
  }

  Future<void> deleteSong(SongModel song) async {
    final audioFile = File(song.data);
    if (_albums[song.album]!.length == 1) {
      _sortedAlbumKeysList.remove(song.album);
    }
    _albums[song.album]!.remove(song);

    if (_artists[song.artist]!.length == 1) {
      _sortedArtistKeysList.remove(song.artist);
    }
    _artists[song.artist]!.remove(song);

    if (_genres[song.genre]!.length == 1) {
      _sortedGenreKeysList.remove(song.genre);
    }
    _genres[song.genre]!.remove(song);

    if (_folders[audioFile.parent.path]!.length == 1) {
      _sortedFolderKeysList.remove(audioFile.parent.path);
    }
    _folders[audioFile.parent.path]!.remove(song);

    _songs.remove(song);
    try {
      await audioFile.delete();
      ShowSnackBar().showSnackBar(
        context,
        'Deleted: ${song.title}',
      );
    } catch (e) {
      //.root.severe('Failed to delete $audioFile.path', e);
      ShowSnackBar().showSnackBar(
        context,
        duration: const Duration(seconds: 5),
        'Failed to delete: ${audioFile.path}\nError: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.title ?? "My Music",
          ),
          //  actions: [
          //   IconButton(
          //     icon: const Icon(CupertinoIcons.search),
          //     tooltip: "Search",
          //     onPressed: () {
          //       showSearch(
          //         context: context,
          //         delegate: DataSearch(
          //           data: _songs,
          //           tempPath: tempPath!,
          //         ),
          //       );
          //     },
          //   ),
          //   if (_currentTabIndex == 0)
          //     PopupMenuButton(
          //       icon: const Icon(Icons.sort_rounded),
          //       shape: const RoundedRectangleBorder(
          //         borderRadius: BorderRadius.all(Radius.circular(15.0)),
          //       ),
          //       onSelected: (int value) async {
          //         if (value < 6) {
          //           sortValue = value;
          //           Hive.box('settings').put('sortValue', value);
          //         } else {
          //           orderValue = value - 6;
          //           Hive.box('settings').put('orderValue', orderValue);
          //         }
          //         await sortSongs(sortValue, orderValue);
          //         setState(() {});
          //       },
          //       itemBuilder: (context) {
          //         final List<String> sortTypes = [
          //           "Name",
          //           "Date added",
          //           "Album",
          //           "Artist",
          //           "Duration",
          //           "Size",
          //         ];
          //         final List<String> orderTypes = [
          //           "Increasing",
          //           "Decreasing",
          //         ];
          //         final menuList = <PopupMenuEntry<int>>[];
          //         menuList.addAll(
          //           sortTypes
          //               .map(
          //                 (e) => PopupMenuItem(
          //                   value: sortTypes.indexOf(e),
          //                   child: Row(
          //                     children: [
          //                       if (sortValue == sortTypes.indexOf(e))
          //                         Icon(
          //                           Icons.check_rounded,
          //                           color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
          //                         )
          //                       else
          //                         const SizedBox(),
          //                       const SizedBox(width: 10),
          //                       Text(
          //                         e,
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               )
          //               .toList(),
          //         );
          //         menuList.add(
          //           const PopupMenuDivider(
          //             height: 10,
          //           ),
          //         );
          //         menuList.addAll(
          //           orderTypes
          //               .map(
          //                 (e) => PopupMenuItem(
          //                   value: sortTypes.length + orderTypes.indexOf(e),
          //                   child: Row(
          //                     children: [
          //                       if (orderValue == orderTypes.indexOf(e))
          //                         Icon(
          //                           Icons.check_rounded,
          //                           color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
          //                         )
          //                       else
          //                         const SizedBox(),
          //                       const SizedBox(width: 10),
          //                       Text(
          //                         e,
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               )
          //               .toList(),
          //         );
          //         return menuList;
          //       },
          //     ),
          // ],

          centerTitle: true,
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Theme.of(context).colorScheme.secondary,
          elevation: 0,
        ),
        body: !added
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SongsTab(
                songs: _songs,
                playlistId: widget.playlistId,
                playlistName: widget.title,
                tempPath: tempPath!,
                deleteSong: deleteSong,
              ),
        // : TabBarView(
        //     physics: const CustomPhysics(),
        //     controller: _tcontroller,
        //     children: [
        //       SongsTab(
        //         songs: _songs,
        //         playlistId: widget.playlistId,
        //         playlistName: widget.title,
        //         tempPath: tempPath!,
        //         deleteSong: deleteSong,
        //       ),
        //       AlbumsTab(
        //         albums: _albums,
        //         albumsList: _sortedAlbumKeysList,
        //         tempPath: tempPath!,
        //       ),
        //       AlbumsTab(
        //         albums: _artists,
        //         albumsList: _sortedArtistKeysList,
        //         tempPath: tempPath!,
        //       ),
        //       AlbumsTab(
        //         albums: _genres,
        //         albumsList: _sortedGenreKeysList,
        //         tempPath: tempPath!,
        //       ),
        //       AlbumsTab(
        //         albums: _folders,
        //         albumsList: _sortedFolderKeysList,
        //         tempPath: tempPath!,
        //         isFolder: true,
        //       ),
        //       // videosTab(),
        //     ],
        //   ),
      );
    } catch (e) {
      print(e);
      return "$e".text.make();
    }
  }
}

class SongsTab extends StatefulWidget {
  final List<SongModel> songs;
  final int? playlistId;
  final String? playlistName;
  final String tempPath;
  final Function(SongModel) deleteSong;
  const SongsTab({
    super.key,
    required this.songs,
    required this.tempPath,
    required this.deleteSong,
    this.playlistId,
    this.playlistName,
  });

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.songs.isEmpty
        ? const Text("Error")
        // ? emptyScreen(
        //     context,
        //     3,
        //     AppLocalizations.of(context)!.nothingTo,
        //     15.0,
        //     AppLocalizations.of(context)!.showHere,
        //     45,
        //     AppLocalizations.of(context)!.downloadSomething,
        //     23.0,
        //   )
        : Scrollbar(
            controller: _scrollController,
            thickness: 8,
            thumbVisibility: true,
            radius: const Radius.circular(10),
            interactive: true,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 10),
              controller: _scrollController,
              shrinkWrap: true,
              itemExtent: 70.0,
              itemCount: widget.songs.length,
              itemBuilder: (context, index) {
                print(widget.tempPath);
                return ListTile(
                  // leading: OfflineAudioQuery.offlineArtworkWidget(
                  //   id: widget.songs[index].id,
                  //   type: ArtworkType.AUDIO,
                  //   tempPath: widget.tempPath,
                  //   fileName: widget.songs[index].displayNameWOExt,
                  // ),
                  title: Text(
                    widget.songs[index].title.trim() != '' ? widget.songs[index].title : widget.songs[index].displayNameWOExt,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${widget.songs[index].artist?.replaceAll('<unknown>', 'Unknown')} - ${widget.songs[index].album?.replaceAll('<unknown>', 'Unknown')}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    ),
                    onSelected: (int? value) async {
                      if (value == 0) {
                        // AddToOffPlaylist().addToOffPlaylist(
                        //   context,
                        //   widget.songs[index].id,
                        // );
                        // ignore: use_build_context_synchronously
                        ShowSnackBar().showSnackBar(
                          context,
                          'Removed from ${widget.playlistName}',
                        );
                      }
                      if (value == 1) {
                        await OfflineAudioQuery().removeFromPlaylist(
                          playlistId: widget.playlistId!,
                          audioId: widget.songs[index].id,
                        );
                        // ignore: use_build_context_synchronously
                        ShowSnackBar().showSnackBar(
                          context,
                          'Removed from ${widget.playlistName}',
                        );
                      }
                      if (value == -1) {
                        await widget.deleteSong(widget.songs[index]);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 0,
                        child: Row(
                          children: [
                            Icon(Icons.playlist_add_rounded),
                            SizedBox(width: 10.0),
                            Text(
                              "Add to playlist",
                            ),
                          ],
                        ),
                      ),
                      if (widget.playlistId != null)
                        const PopupMenuItem(
                          value: 1,
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded),
                              SizedBox(width: 10.0),
                              Text("Remove"),
                            ],
                          ),
                        ),
                      // PopupMenuItem(
                      //       value: 0,
                      //       child: Row(
                      //         children: const [
                      //           Icon(Icons.edit_rounded),
                      //           const SizedBox(width: 10.0),
                      //           Text('Rename'),
                      //         ],
                      //       ),
                      //     ),
                      //     PopupMenuItem(
                      //       value: 1,
                      //       child: Row(
                      //         children: const [
                      //           Icon(
                      //               // CupertinoIcons.tag
                      //               Icons.local_offer_rounded),
                      //           const SizedBox(width: 10.0),
                      //           Text('Edit Tags'),
                      //         ],
                      //       ),
                      //     ),
                      const PopupMenuItem(
                        value: -1,
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded),
                            SizedBox(width: 10.0),
                            Text("Delete"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    PlayerInvoke.init(
                      songsList: widget.songs,
                      index: index,
                      isOffline: true,
                      recommend: false,
                    );
                  },
                );
              },
            ),
          );
  }
}

class AlbumsTab extends StatefulWidget {
  final Map<String, List<SongModel>> albums;
  final List<String> albumsList;
  final String tempPath;
  final bool isFolder;
  const AlbumsTab({
    super.key,
    required this.albums,
    required this.albumsList,
    required this.tempPath,
    this.isFolder = false,
  });

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.albumsList.isEmpty
        ? const Text("Nothing")
        // emptyScreen(
        //     context,
        //     3,
        //     AppLocalizations.of(context)!.nothingTo,
        //     15.0,
        //     AppLocalizations.of(context)!.showHere,
        //     45,
        //     AppLocalizations.of(context)!.downloadSomething,
        //     23.0,
        //   )
        : Scrollbar(
            controller: _scrollController,
            thickness: 8,
            thumbVisibility: true,
            radius: const Radius.circular(10),
            interactive: true,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              controller: _scrollController,
              shrinkWrap: true,
              itemExtent: 70.0,
              itemCount: widget.albumsList.length,
              itemBuilder: (context, index) {
                String title = widget.albumsList[index];
                if (widget.isFolder && title.length > 35) {
                  final splits = title.split('/');
                  title = '${splits.first}/.../${splits.last}';
                }
                return ListTile(
                  leading: OfflineAudioQuery.offlineArtworkWidget(
                    id: widget.albums[widget.albumsList[index]]![0].id,
                    type: ArtworkType.AUDIO,
                    tempPath: widget.tempPath,
                    fileName: widget.albums[widget.albumsList[index]]![0].displayNameWOExt,
                  ),
                  title: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${widget.albums[widget.albumsList[index]]!.length} Songs',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DownloadedSongs(
                          title: widget.albumsList[index],
                          cachedSongs: widget.albums[widget.albumsList[index]],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
  }
}
