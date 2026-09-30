import 'package:dramabyte_app/features/home/domain/entities/genre_rail.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:equatable/equatable.dart';

class HomeFeed extends Equatable {
  const HomeFeed({
    this.featured = const [],
    this.trending = const [],
    this.genres = const [],
  });

  final List<SeriesCard> featured;
  final List<SeriesCard> trending;
  final List<GenreRail> genres;

  bool get isEmpty =>
      featured.isEmpty &&
      trending.isEmpty &&
      genres.every((g) => g.items.isEmpty);

  @override
  List<Object> get props => [featured, trending, genres];
}
