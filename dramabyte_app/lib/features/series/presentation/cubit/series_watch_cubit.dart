import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/series/domain/usecases/series_use_cases.dart';

class SeriesWatchCubit extends Cubit<ResourceState<List<Reel>>> {
  SeriesWatchCubit(this._seriesId, this._playlist)
    : super(ResourceLoading<List<Reel>>());

  final String _seriesId;
  final GetSeriesPlaylist _playlist;

  Future<void> load() async {
    try {
      final reels = await _playlist(_seriesId);
      if (!isClosed) emit(ResourceLoaded<List<Reel>>(reels));
    } on Failure catch (failure) {
      if (!isClosed) emit(ResourceError<List<Reel>>(failure.message));
    }
  }

  Future<void> retry() {
    emit(ResourceLoading<List<Reel>>());
    return load();
  }
}
