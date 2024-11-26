// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      albumID: fields[4] as String,
      dorminantColor: fields[5] as int?,
      darkM: fields[6] as int?,
      lightM: fields[7] as int?,
      syncedLyrics: (fields[8] as List).cast<LyricLine>(),
      artistId: fields[9] as String,
      imageURL: fields[10] as String,
      quality: fields[11] as String,
      release_date: fields[12] as String,
      lyrics: fields[13] as String,
      path: fields[14] as String?,
      imagePath: fields[15] as String?,
      download_date: fields[16] as DateTime,
      year: fields[17] as int?,
      duration: fields[18] as int,
      picture: fields[19] as Uint8List,
      url: fields[20] as String?,
      downloaded: fields[21] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.albumID)
      ..writeByte(5)
      ..write(obj.dorminantColor)
      ..writeByte(6)
      ..write(obj.darkM)
      ..writeByte(7)
      ..write(obj.lightM)
      ..writeByte(8)
      ..write(obj.syncedLyrics)
      ..writeByte(9)
      ..write(obj.artistId)
      ..writeByte(10)
      ..write(obj.imageURL)
      ..writeByte(11)
      ..write(obj.quality)
      ..writeByte(12)
      ..write(obj.release_date)
      ..writeByte(13)
      ..write(obj.lyrics)
      ..writeByte(14)
      ..write(obj.path)
      ..writeByte(15)
      ..write(obj.imagePath)
      ..writeByte(16)
      ..write(obj.download_date)
      ..writeByte(17)
      ..write(obj.year)
      ..writeByte(18)
      ..write(obj.duration)
      ..writeByte(19)
      ..write(obj.picture)
      ..writeByte(20)
      ..write(obj.url)
      ..writeByte(21)
      ..write(obj.downloaded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SongAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class PlaylistsAdapter extends TypeAdapter<Playlists> {
  @override
  final int typeId = 1;

  @override
  Playlists read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Playlists(
      id: fields[0] as String,
      name: fields[1] as String,
      songs: (fields[2] as List).cast<Song>(),
      added: fields[3] as DateTime,
      modified: fields[4] as DateTime,
      author: fields[5] as String,
      imageURL: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Playlists obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.songs)
      ..writeByte(3)
      ..write(obj.added)
      ..writeByte(4)
      ..write(obj.modified)
      ..writeByte(5)
      ..write(obj.author);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlaylistsAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class LyricLineAdapter extends TypeAdapter<LyricLine> {
  @override
  final int typeId = 2;

  @override
  LyricLine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricLine(
      timeTag: fields[0] as int,
      words: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LyricLine obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timeTag)
      ..writeByte(1)
      ..write(obj.words);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LyricLineAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
