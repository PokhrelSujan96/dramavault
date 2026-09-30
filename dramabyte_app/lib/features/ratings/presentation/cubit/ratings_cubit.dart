import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/domain/usecases/rating_use_cases.dart';
import 'package:equatable/equatable.dart';

class RatingsState extends Equatable {
  const RatingsState({this.summaries = const {}});

  final Map<String, RatingSummary> summaries;

  static String key(RatingTarget target, String id) => '${target.name}:$id';

  RatingSummary? of(RatingTarget target, String id) =>
      summaries[key(target, id)];

  @override
  List<Object> get props => [summaries];
}

class RatingsCubit extends Cubit<RatingsState> {
  RatingsCubit(this._rate, this._clear) : super(const RatingsState());

  final RateTitle _rate;
  final ClearRating _clear;
  final _confirmed = <String, RatingSummary>{};
  final _desired = <String, int?>{};
  final _inFlight = <String>{};

  void seed(RatingTarget target, String id, RatingSummary summary) {
    final key = RatingsState.key(target, id);
    if (_inFlight.contains(key)) return;
    _confirmed[key] = summary;
    if (state.summaries[key] == summary) return;
    emit(RatingsState(summaries: {...state.summaries, key: summary}));
  }

  void seedReels(List<Reel> reels) {
    for (final reel in reels) {
      seed(RatingTarget.episode, reel.episodeId, reel.rating);
    }
  }

  Future<String?> rate(RatingTarget target, String id, int rating) =>
      _commit(target, id, rating.clamp(1, 10));

  Future<String?> clear(RatingTarget target, String id) =>
      _commit(target, id, null);

  Future<String?> _commit(RatingTarget target, String id, int? desired) async {
    final key = RatingsState.key(target, id);
    final current = state.summaries[key] ?? const RatingSummary();
    _confirmed.putIfAbsent(key, () => current);
    _desired[key] = desired;
    _put(key, current.withMine(desired));
    if (_inFlight.contains(key)) return null;
    _inFlight.add(key);
    try {
      while (true) {
        final sent = _desired[key];
        final result = sent == null
            ? await _clear(ClearParams(target, id))
            : await _rate(RateParams(target, id, sent));
        _confirmed[key] = result;
        if (_desired[key] == sent) {
          _put(key, result);
          return null;
        }
      }
    } on Failure catch (failure) {
      _put(key, _confirmed[key] ?? const RatingSummary());
      return failure.message;
    } finally {
      _inFlight.remove(key);
    }
  }

  void _put(String key, RatingSummary summary) {
    if (isClosed) return;
    emit(RatingsState(summaries: {...state.summaries, key: summary}));
  }
}
