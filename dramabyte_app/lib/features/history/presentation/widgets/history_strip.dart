import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_cubit.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_message_view.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_placeholder_tile.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HistoryStrip extends StatelessWidget {
  const HistoryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, ResourceState<List<HistoryItem>>>(
      builder: (context, state) => switch (state) {
        ResourceLoaded<List<HistoryItem>>(:final value) when value.isEmpty =>
          const HistoryMessageView(
            message: 'Nothing watched yet. Your history will show up here.',
          ),
        ResourceLoaded<List<HistoryItem>>(:final value) => _Strip(
          children: [for (final item in value) HistoryTile(item: item)],
        ),
        ResourceError<List<HistoryItem>>(:final message) => HistoryMessageView(
          message: message,
          actionLabel: 'Try again',
          onAction: context.read<HistoryCubit>().retry,
        ),
        _ => _Strip(
          children: [
            for (var i = 0; i < 4; i++) const HistoryPlaceholderTile(),
          ],
        ),
      },
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(spacing: 8, children: children),
    );
  }
}
