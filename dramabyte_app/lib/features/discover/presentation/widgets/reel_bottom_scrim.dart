import 'package:flutter/material.dart';

class ReelBottomScrim extends StatelessWidget {
  const ReelBottomScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          widthFactor: 1,
          heightFactor: 0.48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.78),
                  Colors.black.withValues(alpha: 0.48),
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0, 0.35, 0.62, 0.85, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
