import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';

abstract interface class SeriesRepository {
  Future<SeriesDetails?> cached(String seriesId);
  Future<SeriesDetails> fetch(String seriesId);
  Future<List<Reel>> playlist(String seriesId);
}
