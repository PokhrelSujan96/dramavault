import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:dramabyte_app/features/series/presentation/cubit/series_details_cubit.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_close_button.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_details_body.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_details_skeleton.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_message_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SeriesDetailsPage extends StatelessWidget {
  const SeriesDetailsPage({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SeriesDetailsCubit>(param1: seriesId)..load(),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            BlocBuilder<SeriesDetailsCubit, ResourceState<SeriesDetails>>(
              builder: (context, state) => switch (state) {
                ResourceLoaded<SeriesDetails>(:final value) =>
                  SeriesDetailsBody(series: value),
                ResourceError<SeriesDetails>(:final message) =>
                  SeriesMessageView(
                    message: message,
                    actionLabel: 'Try again',
                    onAction: context.read<SeriesDetailsCubit>().retry,
                  ),
                _ => const SeriesDetailsSkeleton(),
              },
            ),
            const Align(
              alignment: Alignment.topRight,
              child: SeriesCloseButton(),
            ),
          ],
        ),
      ),
    );
  }
}
