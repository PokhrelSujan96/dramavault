import 'dart:async';

import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/core/router/auth_redirect.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dramabyte_app/features/authentication/presentation/pages/auth_page.dart';
import 'package:dramabyte_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dramabyte_app/features/history/presentation/pages/history_page.dart';
import 'package:dramabyte_app/features/referral/presentation/pages/referral_page.dart';
import 'package:dramabyte_app/features/series/presentation/pages/series_details_page.dart';
import 'package:dramabyte_app/features/series/presentation/pages/series_watch_page.dart';
import 'package:dramabyte_app/features/settings/presentation/pages/about_page.dart';
import 'package:dramabyte_app/features/settings/presentation/pages/delete_account_page.dart';
import 'package:dramabyte_app/features/settings/presentation/pages/membership_page.dart';
import 'package:dramabyte_app/features/settings/presentation/pages/privacy_page.dart';
import 'package:dramabyte_app/features/settings/presentation/pages/settings_page.dart';
import 'package:dramabyte_app/features/topup/presentation/pages/topup_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.root,
    debugLogDiagnostics: false,
    observers: [_RouteLogger()],
    refreshListenable: _AuthRefresh(getIt<AuthenticationBloc>()),
    redirect: (_, state) => authRedirect(
      signedIn: getIt<AuthenticationBloc>().state is Authenticated,
      matchedLocation: state.matchedLocation,
      uri: state.uri,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboardName,
        builder: (_, _) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.series,
        name: AppRoutes.seriesName,
        builder: (_, state) =>
            SeriesDetailsPage(seriesId: state.pathParameters['seriesId']!),
      ),
      GoRoute(
        path: AppRoutes.watch,
        name: AppRoutes.watchName,
        builder: (_, state) => SeriesWatchPage(
          seriesId: state.pathParameters['seriesId']!,
          startEpisode:
              int.tryParse(state.uri.queryParameters['episode'] ?? '') ?? 1,
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: AppRoutes.historyName,
        builder: (_, _) => const HistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.topup,
        name: AppRoutes.topupName,
        builder: (_, _) => const TopupPage(),
      ),
      GoRoute(
        path: AppRoutes.referral,
        name: AppRoutes.referralName,
        builder: (_, _) => const ReferralPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: AppRoutes.privacyName,
        builder: (_, _) => const PrivacyPage(),
      ),
      GoRoute(
        path: AppRoutes.membership,
        name: AppRoutes.membershipName,
        builder: (_, _) => const MembershipPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: AppRoutes.aboutName,
        builder: (_, _) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        name: AppRoutes.deleteAccountName,
        builder: (_, _) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.root,
        name: AppRoutes.rootName,
        builder: (_, _) => const AuthPage(),
      ),
    ],
  );
}

final class _RouteLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.debug('Route pushed', data: {'route': route.settings.name});
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.debug('Route popped', data: {'route': route.settings.name});
    super.didPop(route, previousRoute);
  }
}

final class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthenticationBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthenticationState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
