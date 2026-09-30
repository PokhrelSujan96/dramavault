import 'package:dramabyte_app/features/home/domain/entities/home_feed.dart';

abstract interface class HomeRepository {
  Future<HomeFeed?> cached();
  Future<HomeFeed> fetch();
}
