import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:flutter/material.dart';

class SeriesBackdrop extends StatelessWidget {
  const SeriesBackdrop({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FlareNetworkImage(imageUrl, cacheWidth: 1000, background: Colors.black),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0, -0.5),
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}
