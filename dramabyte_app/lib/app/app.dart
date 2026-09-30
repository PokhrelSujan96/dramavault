import 'package:dramabyte_app/core/config/app_config.dart';
import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/router/app_router.dart';
import 'package:dramabyte_app/core/theme/app_theme.dart';
import 'package:dramabyte_app/features/app_settings/presentation/cubit/app_settings_cubit.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_cubit.dart';
import 'package:dramabyte_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:dramabyte_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:dramabyte_app/features/ratings/presentation/cubit/ratings_cubit.dart';
import 'package:dramabyte_app/features/referral/presentation/cubit/referral_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/consent_cubit.dart';
import 'package:dramabyte_app/features/topup/presentation/cubit/coin_packages_cubit.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:dramabyte_app/l10n/supported_languages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DramaByteApp extends StatelessWidget {
  const DramaByteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<AppSettingsCubit>()..load()),
          BlocProvider.value(value: getIt<AuthenticationBloc>()),
          BlocProvider.value(value: getIt<ProfileCubit>()),
          BlocProvider.value(value: getIt<ReferralCubit>()),
          BlocProvider.value(value: getIt<HistoryCubit>()),
          BlocProvider.value(value: getIt<HomeCubit>()),
          BlocProvider.value(value: getIt<LibraryCubit>()),
          BlocProvider.value(value: getIt<EngagementCubit>()),
          BlocProvider.value(value: getIt<RatingsCubit>()),
          BlocProvider.value(value: getIt<CoinPackagesCubit>()),
          BlocProvider.value(value: getIt<ConsentCubit>()),
        ],
        child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
          builder: (context, state) {
            return MaterialApp.router(
              title: AppConfig.appName,
              debugShowCheckedModeBanner: false,
              routerConfig: AppRouter.router,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: state.themeMode,
              locale: state.locale,
              supportedLocales: SupportedLanguages.locales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          },
        ),
      ),
    );
  }
}
