import 'dart:async';

import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/comments/domain/usecases/comment_use_cases.dart';

class CommentLikeSync {
  CommentLikeSync(
    this._setLike, {
    required this.delay,
    required this.currentLiked,
    required this.onRevert,
  });

  final SetCommentLike _setLike;
  final Duration delay;
  final bool? Function(String id) currentLiked;
  final void Function(String id, bool confirmed, String message) onRevert;
  final _timers = <String, Timer>{};
  final _confirmed = <String, bool>{};

  void schedule(String id, {required bool before}) {
    _confirmed.putIfAbsent(id, () => before);
    _timers[id]?.cancel();
    _timers[id] = Timer(delay, () => _sync(id));
  }

  Future<void> _sync(String id) async {
    _timers.remove(id);
    final target = currentLiked(id);
    if (target == null || _confirmed[id] == target) return;
    try {
      await _setLike(SetCommentLikeParams(id, liked: target));
      _confirmed[id] = target;
    } on Failure catch (failure) {
      onRevert(id, _confirmed[id] ?? !target, failure.message);
    }
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
  }
}
