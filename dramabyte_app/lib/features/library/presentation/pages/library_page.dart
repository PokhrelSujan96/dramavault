import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_empty_view.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_message_view.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_row.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, required this.onExplore});

  final VoidCallback onExplore;

  void _open(BuildContext context, LibraryItem item) => context.pushNamed(
    AppRoutes.seriesName,
    pathParameters: {'seriesId': item.seriesId},
  );

  Future<void> _remove(BuildContext context, LibraryItem item) async {
    final cubit = context.read<LibraryCubit>();
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final failure = await cubit.toggle(item);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Removed from Library'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => cubit.toggle(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    return Scaffold(
      appBar: AppBar(title: FlareText('| Library').xl, centerTitle: false),
      body: SafeArea(
        child: BlocBuilder<LibraryCubit, ResourceState<List<LibraryItem>>>(
          builder: (context, state) => switch (state) {
            ResourceLoaded<List<LibraryItem>>(:final value)
                when value.isEmpty =>
              LibraryEmptyView(onExplore: onExplore),
            ResourceLoaded<List<LibraryItem>>(:final value) => RefreshIndicator(
              onRefresh: cubit.refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: value.length,
                itemBuilder: (context, index) => LibraryRow(
                  item: value[index],
                  onOpen: () => _open(context, value[index]),
                  onRemove: () => _remove(context, value[index]),
                ),
              ),
            ),
            ResourceError<List<LibraryItem>>(:final message) =>
              LibraryMessageView(message: message, onRetry: cubit.retry),
            _ => const LibrarySkeleton(),
          },
        ),
      ),
    );
  }
}
