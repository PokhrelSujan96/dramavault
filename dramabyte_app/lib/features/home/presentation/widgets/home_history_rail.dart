import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_cubit.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_strip.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class HomeHistoryRail extends StatelessWidget {
  const HomeHistoryRail({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, ResourceState<List<HistoryItem>>>(
      builder: (context, state) {
        if (state is! ResourceLoaded<List<HistoryItem>> ||
            state.value.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(top: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSectionHeader(
                title: 'Watch History',
                onSeeAll: () => context.pushNamed(AppRoutes.historyName),
              ),
              SizedBox(height: 12.h),
              const HistoryStrip(),
            ],
          ),
        );
      },
    );
  }
}
