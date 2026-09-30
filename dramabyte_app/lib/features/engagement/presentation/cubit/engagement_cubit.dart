import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/engagement/domain/entities/episode_engagement.dart';
import 'package:dramabyte_app/features/engagement/domain/usecases/engagement_use_cases.dart';
import 'package:equatable/equatable.dart';

part 'engagement_state.dart';

class EngagementCubit extends Cubit<EngagementState> {
  EngagementCubit(
    this._setLike,
    this._recordView,
    this._flush, {
    this.likeDelay = const Duration(milliseconds: 400),
  }) : super(const EngagementState()) {
    unawaited(_flush(const NoParams()));
  }

  final SetLike _setLike;
  final RecordView _recordView;
  final FlushViews _flush;
  final Duration likeDelay;
  final _confirmed = <String, bool>{};
  final _timers = <String, Timer>{};
  final _inFlight = <String>{};

  void seed(List<Reel> reels) {
    final next = Map<String, EpisodeEngagement>.of(state.episodes);
    var changed = false;
    for (final reel in reels) {
      final id = reel.episodeId;
      if (_timers.containsKey(id) || _inFlight.contains(id)) continue;
      final current = next[id];
      final fresh = EpisodeEngagement(
        views: max(reel.views, current?.views ?? 0),
        likes: reel.likes,
        liked: reel.liked,
        comments: reel.comments,
      );
      _confirmed[id] = reel.liked;
      if (current != fresh) {
        next[id] = fresh;
        changed = true;
      }
    }
    if (changed) emit(state.copyWith(episodes: next));
  }

  void toggleLike(String episodeId) =>
      _setLiked(episodeId, !state.of(episodeId).liked);

  void like(String episodeId) => _setLiked(episodeId, true);

  void viewed(String episodeId) {
    final current = state.of(episodeId);
    _put(episodeId, current.copyWith(views: current.views + 1));
    _recordView(episodeId);
  }

  void adjustComments(String episodeId, int delta) {
    final current = state.of(episodeId);
    _put(
      episodeId,
      current.copyWith(comments: max(0, current.comments + delta)),
    );
  }

  void flush() => unawaited(_flush(const NoParams()));

  void _setLiked(String episodeId, bool liked) {
    final current = state.of(episodeId);
    if (current.liked == liked) return;
    _confirmed.putIfAbsent(episodeId, () => current.liked);
    _put(
      episodeId,
      current.copyWith(
        liked: liked,
        likes: max(0, current.likes + (liked ? 1 : -1)),
      ),
    );
    _timers[episodeId]?.cancel();
    _timers[episodeId] = Timer(likeDelay, () => _sync(episodeId));
  }

  Future<void> _sync(String episodeId) async {
    _timers.remove(episodeId);
    final target = state.of(episodeId).liked;
    if (_confirmed[episodeId] == target) return;
    _inFlight.add(episodeId);
    try {
      await _setLike(SetLikeParams(episodeId, liked: target));
      _confirmed[episodeId] = target;
    } on Failure catch (failure) {
      final current = state.of(episodeId);
      final base = _confirmed[episodeId] ?? !target;
      if (current.liked != base) {
        _put(
          episodeId,
          current.copyWith(
            liked: base,
            likes: max(0, current.likes + (base ? 1 : -1)),
          ),
        );
      }
      if (!isClosed) emit(state.copyWith(notice: failure.message));
    } finally {
      _inFlight.remove(episodeId);
    }
    final settled = _confirmed[episodeId] == state.of(episodeId).liked;
    if (!isClosed && !settled && !_timers.containsKey(episodeId)) {
      _timers[episodeId] = Timer(likeDelay, () => _sync(episodeId));
    }
  }

  void _put(String episodeId, EpisodeEngagement value) {
    if (isClosed) return;
    emit(state.copyWith(episodes: {...state.episodes, episodeId: value}));
  }

  @override
  Future<void> close() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    flush();
    return super.close();
  }
}
