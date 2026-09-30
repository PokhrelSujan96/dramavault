import 'package:dramabyte_app/features/discover/presentation/pages/discover_page.dart';
import 'package:dramabyte_app/features/home/presentation/pages/home_page.dart';
import 'package:dramabyte_app/features/library/presentation/pages/library_page.dart';
import 'package:dramabyte_app/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../cubit/bottom_navigation_cubit.dart';
import '../cubit/bottom_navigation_state.dart';
import '../cubit/nav_style_cubit.dart';
import '../widgets/nav_bar_item.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => BottomNavCubit()),
      BlocProvider(create: (_) => NavStyleCubit()),
    ],
    child: const _DashboardView(),
  );
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  static const _tabs = [
    (label: 'Home', icon: 'home_outline', active: 'home_fill'),
    (label: 'Discover', icon: 'discover_outline', active: 'discover_fill'),
    (label: 'Library', icon: 'bookmark_outline', active: 'bookmark_fill'),
    (label: 'Profile', icon: 'profile_outline', active: 'profile_fill'),
  ];

  @override
  Widget build(BuildContext context) => BlocBuilder<NavStyleCubit, NavStyle>(
    builder: (context, style) => BlocBuilder<BottomNavCubit, BottomNavState>(
      builder: (context, state) {
        final floating = style == NavStyle.floating;
        return Scaffold(
          body: IndexedStack(
            index: state.index,
            children: [
              HomePage(isActive: state.index == 0),
              DiscoverPage(isActive: state.index == 1),
              LibraryPage(
                onExplore: () => context.read<BottomNavCubit>().changeTab(0),
              ),
              const ProfilePage(),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: floating
                ? EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h)
                : EdgeInsets.zero,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: floating ? 8 : 0,
              borderRadius: BorderRadius.circular(floating ? 24.r : 0),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                child: Row(
                  children: [
                    for (var index = 0; index < _tabs.length; index++)
                      NavBarItem(
                        icon: _tabs[index].icon,
                        activeIcon: _tabs[index].active,
                        label: _tabs[index].label,
                        isSelected: state.index == index,
                        onTap: () =>
                            context.read<BottomNavCubit>().changeTab(index),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
