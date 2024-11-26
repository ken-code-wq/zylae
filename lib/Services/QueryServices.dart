// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zylae/Services/classes.dart';

class PlaylistServices {
  Box box = Hive.box<Playlists>('playList');

  Future createPlaylist(
    String name, {
    String? author,
    String? id,
    String? imageURL,
  }) async {
    await box.put(
      name.replaceAll(RegExp(' '), ''),
      Playlists(
        id: id ?? name.replaceAll(RegExp('source'), 'replace'),
        name: name,
        songs: [],
        added: DateTime.now(),
        modified: DateTime.now(),
        author: author ?? "You",
        imageURL: imageURL,
      ),
    );
    print("added $name");
  }

  Future renamePlaylist(String newName, String id) async {
    Playlists? list = await box.get(id);
    List<Song> songs = [];
    songs.addAll(list!.songs);
    await box.put(
      id,
      Playlists(
        id: id,
        name: newName,
        songs: songs,
        added: list.added,
        modified: DateTime.now(),
        author: list.author,
        imageURL: list.imageURL,
      ),
    );
  }

  Future removePlaylist(
    String id,
  ) async {
    box.delete(
      id,
    );
  }

  Future addToPlaylist(String id, Song song) async {
    Playlists? list = await box.get(id);
    List<Song> songs = [];
    songs.addAll((list?.songs ?? []));
    songs.add(song);
    Playlists nList = Playlists(
      id: id,
      name: list!.name,
      songs: songs,
      added: list.added ?? DateTime(2023),
      modified: DateTime.now(),
      author: list.author ?? "You",
      imageURL: list.imageURL,
    );
    await box.put(id, nList);
  }

  Future removeFromPlaylist(String id, int songIndex) async {
    Playlists? list = await box.get(id);
    List<Song> songs = [];
    songs.addAll(list!.songs);
    songs.removeAt(songIndex);
    Playlists nList = Playlists(
      id: id,
      name: list.name,
      songs: songs,
      added: list.added,
      modified: DateTime.now(),
      author: list.author,
      imageURL: list.imageURL,
    );
    await box.put(id, nList);
  }
}
