import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:dramabyte_app/features/series/domain/usecases/series_use_cases.dart';

class SeriesDetailsCubit extends Cubit<ResourceState<SeriesDetails>> {
  SeriesDetailsCubit(this._seriesId, this._cached, this._fetch)
    : super(ResourceLoading<SeriesDetails>());

  final String _seriesId;
  final GetCachedSeries _cached;
  final GetSeries _fetch;

  Future<void> load() async {
    final cached = await _cached(_seriesId);
    if (isClosed) return;
    if (cached != null) emit(ResourceLoaded<SeriesDetails>(cached));
    try {
      final fresh = await _fetch(_seriesId);
      if (!isClosed) emit(ResourceLoaded<SeriesDetails>(fresh));
    } on Failure catch (failure) {
      if (!isClosed && state is! ResourceLoaded<SeriesDetails>) {
        emit(ResourceError<SeriesDetails>(failure.message));
      }
    }
  }

  Future<void> retry() {
    emit(ResourceLoading<SeriesDetails>());
    return load();
  }
}
