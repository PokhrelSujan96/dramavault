import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/discover_feed.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_skeleton.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.isActive});

  final bool isActive;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  bool _activated = false;

  @override
  Widget build(BuildContext context) {
    _activated = _activated || widget.isActive;
    if (!_activated) return const ColoredBox(color: Colors.black);
    return BlocProvider(
      create: (_) => getIt<DiscoverCubit>()..load(),
      child: ColoredBox(
        color: Colors.black,
        child: BlocBuilder<DiscoverCubit, DiscoverState>(
          builder: (context, state) => switch (state.status) {
            DiscoverStatus.loading => const ReelSkeleton(),
            DiscoverStatus.failure => ReelStatusView(
              icon: Icons.cloud_off,
              message: state.error ?? 'Something went wrong',
              actionLabel: 'Try again',
              onAction: context.read<DiscoverCubit>().load,
            ),
            DiscoverStatus.ready when state.reels.isEmpty => ReelStatusView(
              icon: Icons.movie_filter_outlined,
              message: 'No episodes yet. Check back soon.',
              actionLabel: 'Refresh',
              onAction: context.read<DiscoverCubit>().load,
            ),
            DiscoverStatus.ready => DiscoverFeed(
              state: state,
              isActive: widget.isActive,
            ),
          },
        ),
      ),
    );
  }
}
