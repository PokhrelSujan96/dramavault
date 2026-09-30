import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_source.dart';

abstract interface class ReelMediaRepository {
  Future<ReelSource> resolve(Reel reel);
  Future<void> cache(Reel reel);
  void keepDownloads(Set<String> episodeIds);
  Future<void> markPlayed(String episodeId);
}
