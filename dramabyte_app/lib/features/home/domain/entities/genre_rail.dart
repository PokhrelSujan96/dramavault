import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:equatable/equatable.dart';

class GenreRail extends Equatable {
  const GenreRail(this.genre, this.items);

  final String genre;
  final List<SeriesCard> items;

  @override
  List<Object> get props => [genre, items];
}
