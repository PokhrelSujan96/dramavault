import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> toggleLibrary(BuildContext context, LibraryItem item) async {
  final cubit = context.read<LibraryCubit>();
  final wasSaved = cubit.isSaved(item.seriesId);
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  final result = cubit.toggle(item);
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(wasSaved ? 'Removed from Library' : 'Saved to Library'),
    ),
  );
  final failure = await result;
  if (failure != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure)));
  }
}
