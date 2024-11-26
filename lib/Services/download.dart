import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
// import 'package:zylae/lib/Services/ext_storage_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_gen_core/version.gen.dart';
// import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zylae/Services/classes.dart';

import '../Helpers/lyrics.dart';
import 'ext_storage_provider.dart';

class Download with ChangeNotifier {
  static final Map<String, Download> _instances = {};
  final String id;

  factory Download(String id) {
    if (_instances.containsKey(id)) {
      return _instances[id]!;
    } else {
      final instance = Download._internal(id);
      _instances[id] = instance;
      return instance;
    }
  }

  Download._internal(this.id);

  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  // String preferredDownloadQuality = Hive.box('settings').get('downloadQuality', defaultValue: '320 kbps') as String;
  String preferredDownloadQuality = '96 kbps';
  // String preferredYtDownloadQuality = Hive.box('settings').get('ytDownloadQuality', defaultValue: 'High') as String;
  String preferredYtDownloadQuality = 'High';
  // String downloadFormat = Hive.box('settings').get('downloadFormat', defaultValue: 'm4a').toString();
  String downloadFormat = 'm4a';
  // bool createDownloadFolder = Hive.box('settings').get('createDownloadFolder', defaultValue: false) as bool;
  bool createDownloadFolder = false;
  // bool createYoutubeFolder = Hive.box('settings').get('createYoutubeFolder', defaultValue: false) as bool;
  bool createYoutubeFolder = false;
  double? progress = 0.0;
  String lastDownloadId = '';
  bool downloadLyrics = true;
  bool download = true;

  Future<void> prepareDownload(
    BuildContext context,
    Map data, {
    bool createFolder = false,
    String? folderName,
  }) async {
    var status = await Permission.storage.status;
    print('Status is $status');
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    Logger.root.info('Preparing download for ${data['title']}');
    download = true;
    if (Platform.isAndroid || Platform.isIOS) {
      Logger.root.info('Requesting storage permission');
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        Logger.root.info('Request denied');
        await [
          Permission.storage,
          Permission.accessMediaLocation,
          Permission.mediaLibrary,
        ].request();
      }
      await Permission.manageExternalStorage.request();
      status = await Permission.manageExternalStorage.status;
      if (status.isPermanentlyDenied) {
        Logger.root.info('Request permanently denied');
        await openAppSettings();
      }
    }
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    data['title'] = data['title'].toString().split('(From')[0].trim();

    String filename = '';
    final int downFilename = 0;
    if (downFilename == 0) {
      filename = '${data["title"]} - ${data["artist"]}';
    } else if (downFilename == 1) {
      filename = '${data["artist"]} - ${data["title"]}';
    } else {
      filename = '${data["title"]}';
    }
    // String filename = '${data["title"]} - ${data["artist"]}';
    String dlPath = '';
    Logger.root.info('Cached Download path: $dlPath');
    if (filename.length > 200) {
      final String temp = filename.substring(0, 200);
      final List tempList = temp.split(', ');
      tempList.removeLast();
      filename = tempList.join(', ');
    }

    filename = '${filename.replaceAll(avoid, "").replaceAll("  ", " ")}.m4a';
    //TODO get real path
    if (dlPath == '') {
      Logger.root.info('Cached Download path is empty, getting new path');
      String? temp = await ExtStorageProvider.getExtStorage(
        dirName: 'Music',
        writeAccess: true,
      );
      temp = '/storage/emulated/0/Kylae';
      dlPath = temp!;
    }
    Logger.root.info('New Download path: $dlPath');
    if (data['url'].toString().contains('google') && createYoutubeFolder) {
      Logger.root.info('Youtube audio detected, creating Youtube folder');
      dlPath = '$dlPath/YouTube';
      if (!await Directory(dlPath).exists()) {
        Logger.root.info('Creating Youtube folder');
        await Directory(dlPath).create();
      }
    }

    if (createFolder && createDownloadFolder && folderName != null) {
      final String foldername = folderName.replaceAll(avoid, '');
      dlPath = '$dlPath/$foldername';
      if (!await Directory(dlPath).exists()) {
        Logger.root.info('Creating folder $foldername');
        await Directory(dlPath).create();
      }
    }

    final bool exists = await File('$dlPath/$filename').exists();
    if (exists) {
      Logger.root.info('File already exists');
      if (remember.value == true && rememberOption != null) {
        switch (rememberOption) {
          case 0:
            lastDownloadId = data['id'].toString();
            break;
          case 1:
            downloadSong(context, dlPath, filename, data);
            break;
          case 2:
            while (await File('$dlPath/$filename').exists()) {
              filename = filename.replaceAll('.m4a', ' (1).m4a');
            }
            break;
          default:
            lastDownloadId = data['id'].toString();
            break;
        }
      } else {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              title: Text(
                "Already Exists",
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${data['title']}" Already exists. Do you want to download it again?',
                    softWrap: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
              actions: [
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: remember,
                      builder: (
                        BuildContext context,
                        bool rememberValue,
                        Widget? child,
                      ) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor: Theme.of(context).colorScheme.secondary,
                                value: rememberValue,
                                onChanged: (bool? value) {
                                  remember.value = value ?? false;
                                },
                              ),
                              Text(
                                "Remember my choice",
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
                            ),
                            onPressed: () {
                              lastDownloadId = data['id'].toString();
                              Navigator.pop(context);
                              rememberOption = 0;
                            },
                            child: Text(
                              "No",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              // Hive.box('downloads').delete(data['id']);
                              downloadSong(context, dlPath, filename, data);
                              rememberOption = 1;
                            },
                            child: Text("Yes replace"),
                          ),
                          const SizedBox(width: 5.0),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              while (await File('$dlPath/$filename').exists()) {
                                filename = filename.replaceAll('.m4a', ' (1).m4a');
                              }
                              rememberOption = 2;
                              downloadSong(context, dlPath, filename, data);
                            },
                            child: Text(
                              "yes",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary == Colors.white ? Colors.black : null,
                              ),
                            ),
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } else {
      downloadSong(context, dlPath, filename, data);
    }
  }

  Future<void> downloadSong(
    BuildContext context,
    String? dlPath,
    String fileName,
    Map data,
  ) async {
    Logger.root.info('processing download');
    progress = null;
    notifyListeners();
    String? filepath;
    late String filepath2;
    String? appPath;
    final List<int> bytes = [];
    String lyrics = '';
    final artname = fileName.replaceAll('.m4a', '.jpg');
    if (!Platform.isWindows) {
      Logger.root.info('Getting App Path for storing image');
      // appPath = Hive.box('settings').get('tempDirPath')?.toString();
      appPath ??= (await getApplicationDocumentsDirectory()).path;
      print(appPath);
    } else {
      final Directory? temp = await getDownloadsDirectory();
      appPath = temp!.path;
    }

    try {
      Logger.root.info('Creating audio file $dlPath/$fileName');
      await File('$dlPath/$fileName').create(recursive: true).then((value) => filepath = value.path);
      Logger.root.info('Creating image file $appPath/$artname');
      await File('/storage/emulated/0/Kylae/$artname').create(recursive: true).then((value) {
        filepath2 = value.path;
        print(" path is $filepath2");
      });
    } catch (e) {
      Logger.root.info('Error creating files, requesting additional permission');
      if (Platform.isAndroid) {
        PermissionStatus status = await Permission.manageExternalStorage.status;
        if (status.isDenied) {
          Logger.root.info(
            'ManageExternalStorage permission is denied, requesting permission',
          );
          await [
            Permission.manageExternalStorage,
          ].request();
        }
        status = await Permission.manageExternalStorage.status;
        if (status.isPermanentlyDenied) {
          Logger.root.info(
            'ManageExternalStorage Request is permanently denied, opening settings',
          );
          await openAppSettings();
        }
      }

      Logger.root.info('Retrying to create audio file');
      await File('$dlPath/$fileName').create(recursive: true).then((value) => filepath = value.path);

      Logger.root.info('Retrying to create image file');
      await File('$appPath/$artname').create(recursive: true).then((value) => filepath2 = value.path);
    }
    String kUrl = data['url'].toString();

    if (data['url'].toString().contains('google')) {
      Logger.root.info('Fetching youtube download url with preferred quality');
      // filename = filename.replaceAll('.m4a', '.opus');

      kUrl = preferredYtDownloadQuality == 'High' ? data['highUrl'].toString() : data['lowUrl'].toString();
      if (kUrl == 'null') {
        kUrl = data['url'].toString();
      }
    } else {
      Logger.root.info('Fetching jiosaavn download url with preferred quality');
      kUrl = kUrl.replaceAll(
        '_96.',
        "_${preferredDownloadQuality.replaceAll(' kbps', '')}.",
      );
    }

    Logger.root.info('Connecting to Client');
    final client = Client();
    final response = await client.send(Request('GET', Uri.parse(kUrl)));
    final int total = response.contentLength ?? 0;
    int recieved = 0;
    Logger.root.info('Client connected, Starting download');
    response.stream.asBroadcastStream();
    Logger.root.info('broadcasting download state');
    response.stream.listen((value) {
      bytes.addAll(value);
      try {
        recieved += value.length;
        progress = recieved / total;
        notifyListeners();
        if (!download) {
          client.close();
        }
      } catch (e) {
        Logger.root.severe('Error in download: $e');
      }
    }).onDone(() async {
      if (download) {
        Logger.root.info('Download complete, modifying file');
        final file = File(filepath!);
        await file.writeAsBytes(bytes);

        final client = HttpClient();
        final HttpClientRequest request2 = await client.getUrl(Uri.parse(data['image'].toString()));
        final HttpClientResponse response2 = await request2.close();
        final bytes2 = await consolidateHttpClientResponseBytes(response2);
        final File file2 = File(filepath2);

        await file2.writeAsBytes(bytes2);

        final Map<String, String> res = await Lyrics.getLyrics(
          title: data['title'].toString(),
          artist: data['artist'].toString(),
          id: data['id'].toString(),
          saavnHas: false,
        );
        lyrics = res['lyrics'].toString();

        // commented out not to use FFmpeg as it increases the size of the app
        // can uncomment this if you want to use FFmpeg to convert the audio format
        // to any desired codec instead of the default m4a one.

        // final List<String> availableFormats = ['m4a'];
        // if (downloadFormat != 'm4a' &&
        //     availableFormats.contains(downloadFormat)) {
        //   List<String>? argsList;
        //   if (downloadFormat == 'mp3') {
        //     argsList = [
        //       '-y',
        //       '-i',
        //       '$filepath',
        //       '-c:a',
        //       'libmp3lame',
        //       '-b:a',
        //       '320k',
        //       (filepath!.replaceAll('.m4a', '.mp3'))
        //     ];
        //   }
        //   if (downloadFormat == 'm4a') {
        //     argsList = [
        //       '-y',
        //       '-i',
        //       filepath!,
        //       '-c:a',
        //       'aac',
        //       '-b:a',
        //       '320k',
        //       filepath!.replaceAll('.m4a', '.m4a')
        //     ];
        //   }
        //   // await FlutterFFmpeg().executeWithArguments(_argsList);
        //   // await File(filepath!).delete();
        //   // filepath = filepath!.replaceAll('.m4a', '.$downloadFormat');
        // }
        Logger.root.info('Getting audio tags');
        if (Platform.isAndroid) {
          try {
            final Tag tag = Tag(
              title: data['title'].toString(),
              artist: data['artist'].toString(),
              albumArtist: data['album_artist']?.toString() ?? data['artist']?.toString().split(', ')[0] ?? '',
              artwork: filepath2,
              album: data['album'].toString(),
              genre: data['language'].toString(),
              year: data['year'].toString(),
              lyrics: lyrics == '' ? null : lyrics,
              comment: 'Zylae',
            );
            Logger.root.info('Started tag editing');
            final tagger = Audiotagger();
            await tagger.writeTags(
              path: filepath!,
              tag: tag,
            );
            // await Future.delayed(const Duration(seconds: 1), () async {
            //   if (await file2.exists()) {
            //     await file2.delete();
            //   }
            // });
          } catch (e) {
            Logger.root.severe('Error editing tags: $e');
          }
        } else {
          try {
            final Tag tag = Tag(
              title: data['title'].toString(),
              artist: data['artist'].toString(),
              albumArtist: data['album_artist']?.toString() ?? data['artist']?.toString().split(', ')[0] ?? '',
              artwork: filepath2,
              album: data['album'].toString(),
              genre: data['language'].toString(),
              year: data['year'].toString(),
            );
            Logger.root.info('Started tag editing');
            final tagger = Audiotagger();
            await tagger.writeTags(
              path: filepath!,
              tag: tag,
            );
          } catch (e) {
            print(e);
            Logger.root.severe('Error editing tags: $e');
          }
          // Set metadata to file
          // await MetadataGod.writeMetadata(
          //   file: filepath!,
          //   metadata: Metadata(
          //     title: data['title'].toString(),
          //     artist: data['artist'].toString(),
          //     albumArtist: data['album_artist']?.toString() ?? data['artist']?.toString().split(', ')[0] ?? '',
          //     album: data['album'].toString(),
          //     genre: data['language'].toString(),
          //     year: int.parse(data['year'].toString()),
          //     // lyrics: lyrics,
          //     // comment: 'BlackHole',
          //     // trackNumber: 1,
          //     // trackTotal: 12,
          //     // discNumber: 1,
          //     // discTotal: 5,
          //     durationMs: int.parse(data['duration'].toString()) * 1000,
          //     fileSize: file.lengthSync(),
          //     picture: Picture(
          //       data: File(filepath2).readAsBytesSync(),
          //       mimeType: 'image/jpeg',
          //     ),
          //   ),
          // );
        }
        Logger.root.info('Closing connection & notifying listeners');
        client.close();
        lastDownloadId = data['id'].toString();
        progress = 0.0;
        notifyListeners();
        try {
          Logger.root.info('Putting data to downloads database');
          Future<PaletteGenerator> generatePalette(String imageUrl) async {
            final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
              AssetImage(imageUrl),
              size: const Size(5, 5), // You can specify the size for analysis.
            );

            return paletteGenerator;
          }

          final PaletteGenerator palette = await generatePalette(data['image'].toString());

          Song song = Song(
            id: data['id'].toString(),
            title: data['title'].toString(),
            darkM: palette.darkMutedColor!.color.value,
            dorminantColor: palette.dominantColor!.color.value,
            lightM: palette.lightMutedColor!.color.value,
            syncedLyrics: [],
            artistId: "",
            picture: await File(filepath2).readAsBytes(),
            url: filepath,
            downloaded: true,
            artist: data['artist'].toString(),
            album: data['album'].toString(),
            year: data['year'],
            lyrics: lyrics,
            duration: data['duration'],
            release_date: data['release_date'].toString(),
            albumID: data['album_id'].toString(),
            quality: preferredDownloadQuality,
            path: filepath,
            imagePath: filepath2,
            imageURL: data['image'].toString(),
            download_date: DateTime.now(),
          );
          Hive.box('downloads').put(song.id.toString(), song);
        } catch (e) {
          print(e);
        }
        Logger.root.info('Everything done, showing snackbar');
      } else {
        download = true;
        progress = 0.0;
        File(filepath!).delete();
      }
    });
  }
}
