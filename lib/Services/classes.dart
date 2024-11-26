// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

part 'classes.g.dart';

enum Type { artist, album, song, playlist }

class LyricLines {
  final Duration timeTag;
  final String words;
  LyricLines({
    required this.timeTag,
    required this.words,
  });
}

class SongData {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumID;
  final Color? dorminantColor;
  final Color? darkM;
  final Color? lightM;
  final List<LyricLine> syncedLyrics;
  final String artistId;
  final String imageURL;
  final String quality;
  final String release_date;
  final String lyrics;
  final String? path;
  final String? imagePath;
  final DateTime download_date;
  final int? year;
  final int duration;
  final Uint8List picture;
  final String? url;
  final bool downloaded;

  SongData({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumID,
    required this.dorminantColor,
    required this.darkM,
    required this.lightM,
    required this.syncedLyrics,
    required this.artistId,
    required this.imageURL,
    required this.quality,
    required this.release_date,
    required this.lyrics,
    required this.path,
    required this.imagePath,
    required this.download_date,
    required this.year,
    required this.duration,
    required this.picture,
    required this.url,
    required this.downloaded,
  });
}

class PlaylistData {
  final String id;
  final String name;
  final List<SongData> songs;
  final DateTime added;
  final DateTime modified;
  final String author;
  PlaylistData({
    required this.id,
    required this.name,
    required this.songs,
    required this.added,
    required this.modified,
    required this.author,
  });
}

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String albumID;

  @HiveField(5)
  final int? dorminantColor;

  @HiveField(6)
  final int? darkM;

  @HiveField(7)
  final int? lightM;

  @HiveField(8)
  final List<LyricLine> syncedLyrics;

  @HiveField(9)
  final String artistId;

  @HiveField(10)
  final String imageURL;

  @HiveField(11)
  final String quality;

  @HiveField(12)
  final String release_date;

  @HiveField(13)
  final String lyrics;

  @HiveField(14)
  final String? path;

  @HiveField(15)
  final String? imagePath;

  @HiveField(16)
  final DateTime download_date;

  @HiveField(17)
  final int? year;

  @HiveField(18)
  final int duration;
  @HiveField(19)
  final Uint8List picture;
  @HiveField(20)
  final String? url;
  @HiveField(21)
  final bool downloaded;
  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumID,
    required this.dorminantColor,
    required this.darkM,
    required this.lightM,
    required this.syncedLyrics,
    required this.artistId,
    required this.imageURL,
    required this.quality,
    required this.release_date,
    required this.lyrics,
    required this.path,
    required this.imagePath,
    required this.download_date,
    required this.year,
    required this.duration,
    required this.picture,
    required this.url,
    required this.downloaded,
  });

  // Song({
  //   this.id,
  //   this.title,
  //   this.altTitle,
  //   this.season,
  //   this.ongoing,
  //   this.hbId,
  //   this.createdAt,
  //   this.updatedAt,
  //   this.hidden,
  //   this.malId,
  // });
}

@HiveType(typeId: 1)
class Playlists extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<Song> songs;

  @HiveField(3)
  final DateTime added;

  @HiveField(4)
  final DateTime modified;

  @HiveField(5)
  final String author;

  @HiveField(6)
  final String? imageURL;

  Playlists({
    required this.id,
    required this.name,
    required this.songs,
    required this.added,
    required this.modified,
    required this.author,
    required this.imageURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'songs': songs.toList(),
      'added': added.millisecondsSinceEpoch,
      'modified': modified.millisecondsSinceEpoch,
      'author': author,
    };
  }

  static Playlists? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    try {
      return Playlists(
        id: map['id'],
        name: map['name'],
        songs: map['songs'],
        added: DateTime.fromMillisecondsSinceEpoch(map['added']),
        modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
        author: map['author'],
        imageURL: map['imageURL'],
      );
    } catch (e) {
      return null;
    }
  }

  String toJson() => json.encode(toMap());

  static Playlists? fromJson(String source) => Playlists.fromMap(json.decode(source));
}

@HiveType(typeId: 2)
class LyricLine extends HiveObject {
  @HiveField(0)
  final int timeTag;

  @HiveField(1)
  final String words;

  LyricLine({
    required this.timeTag,
    required this.words,
  });
}

class KStates extends ChangeNotifier {
  bool _error = false;
  bool get error => _error;

  late AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  AudioPlayerProvider() {
    _player = AudioPlayer();
  }

  late OnAudioQuery _audioQuery = OnAudioQuery();
  OnAudioQuery get audioQuery => _audioQuery;
  AudioQueryProvider() {
    _audioQuery = OnAudioQuery();
  }

  List<SongModel> _downloadedsongs = [];
  List<SongModel> get songs => _downloadedsongs;

  void giveSongs(List<SongModel> s) {
    _downloadedsongs = s;
    try {
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  int _currentPlaying = 0;
  int get currentPlaying => _currentPlaying;
  void cPlay(int value) {
    _currentPlaying = value;
    notifyListeners();
  }

  List _tags = [];
  List _pics = [];
  List get pics => _pics;
  List get tags => _tags;
  void setLists(List mTags, List pictures) async {
    _tags = mTags;
    _pics = pictures;
    notifyListeners();
  }

  bool _loadHome = true;
  bool get loadHome => _loadHome;
  bool _loadFiles = true;
  bool get loadFiles => _loadFiles;
  void setLoadState(bool home, bool files) {
    _loadFiles = files;
    _loadHome = home;
    notifyListeners();
  }

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  void loadState(bool state) {
    _isLoaded = state;
    notifyListeners();
  }

  int _currentPage = 0;
  int get currentPage => _currentPage;

  void setCP(int val) {
    _currentPage = val;
    notifyListeners();
  }

  Map _apiData = {};
  Map get apiData => _apiData;

  void setApiData(Map val) {
    _apiData = val;
    notifyListeners();
  }

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void changePS(bool val) {
    _isPlaying = val;
    notifyListeners();
  }

  final PanelController _panelController = PanelController();
  PanelController get panelController => _panelController;
}
