import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/home/domain/entities/home_feed.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_content.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_message_view.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.isActive});

  final bool isActive;

  void _open(BuildContext context, SeriesCard card) => context.pushNamed(
    AppRoutes.seriesName,
    pathParameters: {'seriesId': card.seriesId},
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    return Scaffold(
      body: BlocBuilder<HomeCubit, ResourceState<HomeFeed>>(
        builder: (context, state) => switch (state) {
          ResourceLoaded<HomeFeed>(:final value) when value.isEmpty =>
            HomeMessageView(
              message: 'No shows yet. Check back soon.',
              actionLabel: 'Refresh',
              onAction: cubit.retry,
            ),
          ResourceLoaded<HomeFeed>(:final value) => RefreshIndicator(
            onRefresh: cubit.refresh,
            child: HomeContent(
              feed: value,
              isActive: isActive,
              onOpen: (card) => _open(context, card),
            ),
          ),
          ResourceError<HomeFeed>(:final message) => HomeMessageView(
            message: message,
            actionLabel: 'Try again',
            onAction: cubit.retry,
          ),
          _ => const HomeSkeleton(),
        },
      ),
    );
  }
}
