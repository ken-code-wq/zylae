import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

import '../Services/classes.dart';

class FourPicArtwork extends StatelessWidget {
  final double height;
  final double width;
  final List<Song> songs;
  const FourPicArtwork({super.key, required this.height, required this.width, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: height,
      // width: width,
      child: songs.length == 1
          ? Image.memory(
              songs[0].picture,
              height: height,
              width: width,
              fit: BoxFit.cover,
            )
          : songs.length <= 3 && songs.isNotEmpty
              ? Row(
                  children: [
                    Image.memory(
                      songs[0].picture,
                      height: height,
                      width: width / 2,
                      fit: BoxFit.cover,
                    ),
                    Image.memory(
                      songs[1].picture,
                      height: height,
                      width: width / 2,
                      fit: BoxFit.cover,
                    )
                  ],
                )
              : songs.length >= 4
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Image.memory(
                              songs[0].picture,
                              height: height / 2,
                              width: width / 2,
                              fit: BoxFit.cover,
                            ),
                            Image.memory(
                              songs[1].picture,
                              height: height / 2,
                              width: width / 2,
                              fit: BoxFit.cover,
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Image.memory(
                              songs[2].picture,
                              height: height / 2,
                              width: width / 2,
                              fit: BoxFit.cover,
                            ),
                            Image.memory(
                              songs[3].picture,
                              height: height / 2,
                              width: width / 2,
                              fit: BoxFit.cover,
                            )
                          ],
                        ),
                      ],
                    )
                  : "OK".text.make(),
    );
  }
}
