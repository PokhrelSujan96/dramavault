import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/connectivity/connectivity_cubit.dart';
import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/core/network/auth_interceptor.dart';
import 'package:dramabyte_app/core/network/token_refresher.dart';
import 'package:dramabyte_app/core/realtime/realtime_service.dart';
import 'package:dramabyte_app/core/security/app_security.dart';
import 'package:dramabyte_app/core/security/secure_storage.dart';
import 'package:dramabyte_app/features/app_settings/data/repositories/app_settings_repository_impl.dart';
import 'package:dramabyte_app/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:dramabyte_app/features/app_settings/presentation/cubit/app_settings_cubit.dart';
import 'package:dramabyte_app/features/authentication/data/datasources/auth_remote_source.dart';
import 'package:dramabyte_app/features/authentication/data/datasources/google_sign_in_source.dart';
import 'package:dramabyte_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:dramabyte_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:dramabyte_app/features/authentication/domain/usecases/auth_use_cases.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dramabyte_app/features/comments/data/datasources/comment_remote_source.dart';
import 'package:dramabyte_app/features/comments/data/repositories/comment_repository_impl.dart';
import 'package:dramabyte_app/features/comments/domain/repositories/comment_repository.dart';
import 'package:dramabyte_app/features/comments/domain/usecases/comment_use_cases.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_args.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:dramabyte_app/features/discover/data/datasources/discover_remote_source.dart';
import 'package:dramabyte_app/features/discover/data/datasources/reel_database.dart';
import 'package:dramabyte_app/features/discover/data/datasources/reel_file_store.dart';
import 'package:dramabyte_app/features/discover/data/repositories/discover_repository_impl.dart';
import 'package:dramabyte_app/features/discover/data/repositories/reel_media_repository_impl.dart';
import 'package:dramabyte_app/features/discover/domain/repositories/discover_repository.dart';
import 'package:dramabyte_app/features/discover/domain/repositories/reel_media_repository.dart';
import 'package:dramabyte_app/features/discover/domain/usecases/discover_use_cases.dart';
import 'package:dramabyte_app/features/discover/domain/usecases/reel_media_use_cases.dart';
import 'package:dramabyte_app/features/discover/presentation/controllers/reel_player_pool.dart';
import 'package:dramabyte_app/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:dramabyte_app/features/engagement/data/datasources/engagement_remote_source.dart';
import 'package:dramabyte_app/features/engagement/data/datasources/view_batcher.dart';
import 'package:dramabyte_app/features/engagement/data/repositories/engagement_repository_impl.dart';
import 'package:dramabyte_app/features/engagement/domain/repositories/engagement_repository.dart';
import 'package:dramabyte_app/features/engagement/domain/usecases/engagement_use_cases.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:dramabyte_app/features/history/data/datasources/history_remote_source.dart';
import 'package:dramabyte_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:dramabyte_app/features/history/domain/repositories/history_repository.dart';
import 'package:dramabyte_app/features/history/domain/usecases/history_use_cases.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_cubit.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_list_cubit.dart';
import 'package:dramabyte_app/features/home/data/datasources/home_remote_source.dart';
import 'package:dramabyte_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:dramabyte_app/features/home/domain/repositories/home_repository.dart';
import 'package:dramabyte_app/features/home/domain/usecases/home_use_cases.dart';
import 'package:dramabyte_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:dramabyte_app/features/library/data/datasources/library_remote_source.dart';
import 'package:dramabyte_app/features/library/data/repositories/library_repository_impl.dart';
import 'package:dramabyte_app/features/library/domain/repositories/library_repository.dart';
import 'package:dramabyte_app/features/library/domain/usecases/library_use_cases.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:dramabyte_app/features/profile/data/datasources/profile_remote_source.dart';
import 'package:dramabyte_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:dramabyte_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:dramabyte_app/features/profile/domain/usecases/profile_use_cases.dart';
import 'package:dramabyte_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:dramabyte_app/features/ratings/data/datasources/rating_remote_source.dart';
import 'package:dramabyte_app/features/ratings/data/repositories/rating_repository_impl.dart';
import 'package:dramabyte_app/features/ratings/domain/repositories/rating_repository.dart';
import 'package:dramabyte_app/features/ratings/domain/usecases/rating_use_cases.dart';
import 'package:dramabyte_app/features/ratings/presentation/cubit/ratings_cubit.dart';
import 'package:dramabyte_app/features/referral/data/datasources/referral_remote_source.dart';
import 'package:dramabyte_app/features/referral/data/repositories/referral_repository_impl.dart';
import 'package:dramabyte_app/features/referral/domain/repositories/referral_repository.dart';
import 'package:dramabyte_app/features/referral/domain/usecases/referral_use_cases.dart';
import 'package:dramabyte_app/features/referral/presentation/cubit/referral_cubit.dart';
import 'package:dramabyte_app/features/search/data/datasources/search_local_source.dart';
import 'package:dramabyte_app/features/search/data/datasources/search_remote_source.dart';
import 'package:dramabyte_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:dramabyte_app/features/search/domain/repositories/search_repository.dart';
import 'package:dramabyte_app/features/search/domain/usecases/search_use_cases.dart';
import 'package:dramabyte_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:dramabyte_app/features/series/data/datasources/series_remote_source.dart';
import 'package:dramabyte_app/features/series/data/repositories/series_repository_impl.dart';
import 'package:dramabyte_app/features/series/domain/repositories/series_repository.dart';
import 'package:dramabyte_app/features/series/domain/usecases/series_use_cases.dart';
import 'package:dramabyte_app/features/series/presentation/cubit/series_details_cubit.dart';
import 'package:dramabyte_app/features/series/presentation/cubit/series_watch_cubit.dart';
import 'package:dramabyte_app/features/settings/data/datasources/account_remote_source.dart';
import 'package:dramabyte_app/features/settings/data/repositories/account_repository_impl.dart';
import 'package:dramabyte_app/features/settings/data/repositories/cache_repository_impl.dart';
import 'package:dramabyte_app/features/settings/data/repositories/consent_repository_impl.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/account_repository.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/cache_repository.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/consent_repository.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/cache_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/consent_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/delete_account_cubit.dart';
import 'package:dramabyte_app/features/topup/data/datasources/topup_remote_source.dart';
import 'package:dramabyte_app/features/topup/data/gateways/sandbox_payment_gateway.dart';
import 'package:dramabyte_app/features/topup/data/repositories/topup_repository_impl.dart';
import 'package:dramabyte_app/features/topup/domain/gateways/payment_gateway.dart';
import 'package:dramabyte_app/features/topup/domain/repositories/topup_repository.dart';
import 'package:dramabyte_app/features/topup/domain/usecases/topup_use_cases.dart';
import 'package:dramabyte_app/features/topup/presentation/cubit/coin_packages_cubit.dart';
import 'package:dramabyte_app/features/topup/presentation/cubit/topup_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final preferences = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<SharedPreferences>(preferences)
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    )
    ..registerLazySingleton<SecureStorage>(
      () => FlutterSecureStorageService(getIt()),
    )
    ..registerLazySingleton(AppSecurity.new)
    ..registerLazySingleton(() => TokenRefresher(getIt()))
    ..registerLazySingleton(() => AuthInterceptor(getIt()))
    ..registerLazySingleton(() => JsonCache(getIt()))
    ..registerLazySingleton(() => RealtimeService(getIt()))
    ..registerLazySingleton(() => ApiClient(getIt()))
    ..registerLazySingleton(Connectivity.new)
    ..registerFactory(() => ConnectivityCubit(getIt())..check())
    ..registerLazySingleton<AppSettingsRepository>(
      () => AppSettingsRepositoryImpl(getIt()),
    )
    ..registerFactory(() => AppSettingsCubit(getIt()))
    ..registerLazySingleton(() => AccountRemoteSource(getIt()))
    ..registerLazySingleton<ConsentRepository>(
      () => ConsentRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<CacheRepository>(
      () => CacheRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton(() => ConsentCubit(getIt()))
    ..registerFactory(() => CacheCubit(getIt()))
    ..registerFactory(() => DeleteAccountCubit(getIt(), getIt(), getIt()))
    ..registerLazySingleton(() => AuthRemoteSource(getIt()))
    ..registerLazySingleton(GoogleSignInSource.new)
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton(() => ReferralRemoteSource(getIt()))
    ..registerLazySingleton<ReferralRepository>(
      () => ReferralRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton(
      () => ReferralCubit(
        getIt(),
        GetCachedReferral(getIt()),
        GetReferralSummary(getIt()),
        WatchReferralChanges(getIt()),
      ),
    )
    ..registerLazySingleton(() => TopupRemoteSource(getIt()))
    ..registerLazySingleton<TopupRepository>(
      () => TopupRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<PaymentGateway>(SandboxPaymentGateway.new)
    ..registerLazySingleton(
      () => CoinPackagesCubit(
        getIt(),
        GetCachedCoinPackages(getIt()),
        GetCoinPackages(getIt()),
        WatchCoinPackageChanges(getIt()),
      ),
    )
    ..registerFactory(
      () =>
          TopupCubit(CreateTopupOrder(getIt()), ConfirmTopup(getIt()), getIt()),
    )
    ..registerLazySingleton(() => RatingRemoteSource(getIt()))
    ..registerLazySingleton<RatingRepository>(
      () => RatingRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(
      () => RatingsCubit(RateTitle(getIt()), ClearRating(getIt())),
    )
    ..registerLazySingleton(() => CommentRemoteSource(getIt()))
    ..registerLazySingleton<CommentRepository>(
      () => CommentRepositoryImpl(getIt()),
    )
    ..registerFactoryParam<CommentsCubit, CommentsArgs, void>(
      (args, _) => CommentsCubit(
        args,
        ListComments(getIt()),
        ListReplies(getIt()),
        PostComment(getIt()),
        SetCommentLike(getIt()),
        DeleteComment(getIt()),
        ReportComment(getIt()),
        onCountChanged: (delta) =>
            getIt<EngagementCubit>().adjustComments(args.episodeId, delta),
      ),
    )
    ..registerLazySingleton(() => EngagementRemoteSource(getIt()))
    ..registerLazySingleton(
      () => ViewBatcher(getIt<EngagementRemoteSource>().sendViews, getIt()),
    )
    ..registerLazySingleton<EngagementRepository>(
      () => EngagementRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton(
      () => EngagementCubit(
        SetLike(getIt()),
        RecordView(getIt()),
        FlushViews(getIt()),
      ),
    )
    ..registerLazySingleton(() => LibraryRemoteSource(getIt()))
    ..registerLazySingleton<LibraryRepository>(
      () => LibraryRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton(
      () => LibraryCubit(
        getIt(),
        GetCachedLibrary(getIt()),
        GetLibrary(getIt()),
        WatchLibraryChanges(getIt()),
        AddToLibrary(getIt()),
        RemoveFromLibrary(getIt()),
      ),
    )
    ..registerLazySingleton(() => SearchRemoteSource(getIt()))
    ..registerLazySingleton(() => SearchLocalSource(getIt()))
    ..registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactory(
      () => SearchCubit(
        SearchSeries(getIt()),
        GetRecentSearches(getIt()),
        SaveRecentSearch(getIt()),
        RemoveRecentSearch(getIt()),
        ClearRecentSearches(getIt()),
      ),
    )
    ..registerLazySingleton(() => SeriesRemoteSource(getIt()))
    ..registerLazySingleton<SeriesRepository>(
      () => SeriesRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactoryParam<SeriesDetailsCubit, String, void>(
      (seriesId, _) => SeriesDetailsCubit(
        seriesId,
        GetCachedSeries(getIt()),
        GetSeries(getIt()),
      ),
    )
    ..registerFactoryParam<SeriesWatchCubit, String, void>(
      (seriesId, _) => SeriesWatchCubit(seriesId, GetSeriesPlaylist(getIt())),
    )
    ..registerLazySingleton(() => HomeRemoteSource(getIt()))
    ..registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton(
      () => HomeCubit(getIt(), GetCachedHome(getIt()), GetHome(getIt())),
    )
    ..registerLazySingleton(() => HistoryRemoteSource(getIt()))
    ..registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton(
      () => HistoryCubit(
        getIt(),
        GetCachedHistory(getIt()),
        GetRecentHistory(getIt()),
        WatchHistoryChanges(getIt()),
      ),
    )
    ..registerFactory(
      () => HistoryListCubit(GetHistoryPage(getIt()), RemoveHistory(getIt())),
    )
    ..registerLazySingleton(() => DiscoverRemoteSource(getIt()))
    ..registerLazySingleton(ReelDatabase.new)
    ..registerLazySingleton(ReelFileStore.new)
    ..registerLazySingleton<DiscoverRepository>(
      () => DiscoverRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<ReelMediaRepository>(
      () => ReelMediaRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactory(
      () => DiscoverCubit(
        GetCachedReelPage(getIt()),
        GetReelPage(getIt()),
        GetOfflineReels(getIt()),
      ),
    )
    ..registerFactory(
      () => ReelPlayerPool(
        ResolveReelSource(getIt()).call,
        CacheReelVideo(getIt()).call,
        MarkReelPlayed(getIt()).call,
        KeepReelDownloads(getIt()).call,
        (id, seconds) => RecordWatch(getIt())(RecordWatchParams(id, seconds)),
        getIt<EngagementCubit>().viewed,
        getIt<EngagementCubit>().flush,
      ),
    )
    ..registerLazySingleton(() => ProfileRemoteSource(getIt()))
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton(
      () => ProfileCubit(
        getIt(),
        GetCachedProfile(getIt()),
        GetMyProfile(getIt()),
        WatchProfileChanges(getIt()),
      ),
    )
    ..registerLazySingleton(
      () => AuthenticationBloc(
        RestoreSession(getIt()),
        SignInWithGoogle(getIt()),
        SignOut(getIt()),
        GetCachedUser(getIt()),
        getIt<TokenRefresher>().onSessionExpired,
      ),
    );
}
