import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:flutter/material.dart';

class HomeSpotlightBackdrop extends StatelessWidget {
  const HomeSpotlightBackdrop({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: SizedBox.expand(
            key: ValueKey(imageUrl),
            child: FlareNetworkImage(
              imageUrl,
              cacheWidth: 800,
              background: Colors.black,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC000000), Color(0xB3000000), Color(0xF2000000)],
              stops: [0, 0.5, 1],
            ),
          ),
        ),
      ],
    );
  }
}
