import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_cubit.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_list_cubit.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_message_view.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HistoryListCubit>()..load(),
      child: BlocConsumer<HistoryListCubit, HistoryListState>(
        listenWhen: (previous, state) =>
            state.noticeSeq != previous.noticeSeq && state.notice != null,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.notice!))),
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: FlareText('| History').xl,
            centerTitle: false,
            actions: [
              if (state.items.isNotEmpty)
                IconButton(
                  icon: Icon(MdiIcons.deleteSweepOutline),
                  onPressed: () => _clear(context),
                ),
            ],
          ),
          body: SafeArea(child: _Body(state: state)),
        ),
      ),
    );
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear watch history?'),
        content: const Text('This removes every episode from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<HistoryCubit>().update((_) => const []);
    await context.read<HistoryListCubit>().remove(null);
    if (context.mounted) await context.read<HistoryCubit>().refresh();
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final HistoryListState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HistoryListCubit>();
    return switch (state.status) {
      HistoryListStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      HistoryListStatus.failure => HistoryMessageView(
        message: state.error ?? 'Something went wrong',
        actionLabel: 'Try again',
        onAction: cubit.load,
      ),
      HistoryListStatus.ready when state.items.isEmpty =>
        const HistoryMessageView(message: 'No watch history yet.'),
      HistoryListStatus.ready => NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) cubit.loadMore();
          return false;
        },
        child: ListView.builder(
          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
          itemBuilder: (context, index) => index >= state.items.length
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : HistoryRow(
                  item: state.items[index],
                  onRemove: () async {
                    final strip = context.read<HistoryCubit>();
                    final id = state.items[index].episodeId;
                    strip.update(
                      (items) => [
                        for (final item in items)
                          if (item.episodeId != id) item,
                      ],
                    );
                    await cubit.remove(id);
                    await strip.refresh();
                  },
                ),
        ),
      ),
    };
  }
}
