import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:dramabyte_app/features/series/domain/repositories/series_repository.dart';

final class GetCachedSeries implements UseCase<SeriesDetails?, String> {
  GetCachedSeries(this._repository);

  final SeriesRepository _repository;

  @override
  Future<SeriesDetails?> call(String params) => _repository.cached(params);
}

final class GetSeries implements UseCase<SeriesDetails, String> {
  GetSeries(this._repository);

  final SeriesRepository _repository;

  @override
  Future<SeriesDetails> call(String params) => _repository.fetch(params);
}

final class GetSeriesPlaylist implements UseCase<List<Reel>, String> {
  GetSeriesPlaylist(this._repository);

  final SeriesRepository _repository;

  @override
  Future<List<Reel>> call(String params) => _repository.playlist(params);
}
