import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_page.dart';

abstract interface class DiscoverRepository {
  Future<ReelPage?> cachedFirstPage();
  Future<ReelPage> fetchPage({String? cursor});
  Future<List<Reel>> offlineReels();
}
