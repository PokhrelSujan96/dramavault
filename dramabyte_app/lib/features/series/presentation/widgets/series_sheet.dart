import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeriesSheet extends StatelessWidget {
  const SeriesSheet({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.62,
      maxChildSize: 0.94,
      snap: true,
      builder: (context, controller) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              background.withValues(alpha: 0),
              background.withValues(alpha: 0.88),
              background,
            ],
            stops: const [0, 0.14, 0.26],
          ),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.only(top: 56.h),
          children: children,
        ),
      ),
    );
  }
}
