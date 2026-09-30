import 'dart:async';
import 'dart:io';

import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_source.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

final class PlayerSlot {
  final controller = ValueNotifier<VideoPlayerController?>(null);
  final failed = ValueNotifier<bool>(false);
  final language = ValueNotifier<String>('en');
  bool loading = false;
  int furthest = 0;
  int reported = 0;
  bool viewed = false;
}

final class ReelPlayerPool {
  ReelPlayerPool(
    this._resolve,
    this._cache,
    this._markPlayed,
    this._keepDownloads,
    this._onWatched,
    this._onViewed,
    this._onLeave,
  );

  static const _viewAfter = Duration(seconds: 2);
  static const _minSeconds = 3;
  static const _reportEvery = 15;
  static const _speeds = [1.0, 1.25, 1.5, 2.0];
  final Future<ReelSource> Function(Reel) _resolve;
  final Future<void> Function(Reel) _cache;
  final Future<void> Function(String) _markPlayed;
  final void Function(Set<String>) _keepDownloads;
  final Future<void> Function(String, int) _onWatched;
  final void Function(String) _onViewed;
  final VoidCallback _onLeave;
  final _slots = <String, PlayerSlot>{};
  final _revisions = <String, String>{};
  final _selectedLanguages = <String, String>{};
  final _seekPositions = <String, Duration>{};
  final _reels = <String, Reel>{};
  final speed = ValueNotifier<double>(1);
  Set<String> _window = {};
  String? _currentId;
  bool _active = true;
  bool _userPaused = false;
  bool _disposed = false;

  PlayerSlot slot(String id) => _slots.putIfAbsent(id, PlayerSlot.new);

  bool updateReels(List<Reel> reels) {
    var changed = false;
    for (final reel in reels) {
      final revision = _revision(reel);
      final previous = _revisions[reel.episodeId];
      _reels[reel.episodeId] = reel;
      _revisions[reel.episodeId] = revision;
      if (previous != null && previous != revision) {
        changed = true;
        _unload(reel.episodeId);
      }
    }
    return changed;
  }

  void focus(List<Reel> reels, int index) {
    if (index < 0 || index >= reels.length) return;
    if (_currentId != reels[index].episodeId) {
      _report(_currentId);
      _resetViewed(_currentId);
      _userPaused = false;
    }
    _currentId = reels[index].episodeId;
    final window = [
      for (var i = index - 1; i <= index + 1; i++)
        if (i >= 0 && i < reels.length) reels[i],
    ];
    _window = {for (final reel in window) reel.episodeId};
    _slots.keys.where((id) => !_window.contains(id)).forEach(_unload);
    _keepDownloads({
      _currentId!,
      if (index + 1 < reels.length) reels[index + 1].episodeId,
    });
    unawaited(_load(reels[index]));
    window.where((r) => r.episodeId != _currentId).forEach(_load);
    _sync();
    if (_active) unawaited(_markPlayed(_currentId!));
  }

  void setActive(bool active) {
    if (!active) {
      _report(_currentId);
      _resetViewed(_currentId);
      _onLeave();
    }
    _active = active;
    _sync();
  }

  void toggle(String id) {
    final controller = slot(id).controller.value;
    if (controller == null) return;
    _userPaused = controller.value.isPlaying;
    unawaited(_userPaused ? controller.pause() : controller.play());
  }

  void cycleSpeed() {
    final next = _speeds[(_speeds.indexOf(speed.value) + 1) % _speeds.length];
    speed.value = next;
    for (final slot in _slots.values) {
      unawaited(
        slot.controller.value?.setPlaybackSpeed(next) ?? Future.value(),
      );
    }
  }

  void toggleLanguage(Reel reel) {
    if (!reel.videoVariants.containsKey('hi')) return;
    final language = _language(reel.episodeId) == 'en' ? 'hi' : 'en';
    final current = slot(reel.episodeId).controller.value;
    if (current != null) {
      _seekPositions[reel.episodeId] = current.value.position;
    }
    _selectedLanguages[reel.episodeId] = language;
    slot(reel.episodeId).language.value = language;
    _unload(reel.episodeId);
    unawaited(_load(reel));
    _sync();
  }

  Future<void> retry(Reel reel) => _load(reel);

  Future<void> _load(Reel reel) async {
    final slot = this.slot(reel.episodeId);
    if (slot.loading || slot.controller.value != null) return;
    final requestedLanguage = _language(reel.episodeId);
    slot.loading = true;
    slot.failed.value = false;
    VideoPlayerController? controller;
    try {
      final language = requestedLanguage;
      final localizedUrl = reel.videoVariants[language];
      final source = localizedUrl != null
          ? ReelSource(localizedUrl, isLocal: false)
          : await _resolve(reel);
      controller = source.isLocal
          ? VideoPlayerController.file(File(source.location))
          : VideoPlayerController.networkUrl(Uri.parse(source.location));
      await controller.initialize().timeout(const Duration(seconds: 20));
      if (_revisions[reel.episodeId] != _revision(reel) ||
          _language(reel.episodeId) != language) {
        await controller.dispose();
        controller = null;
        return;
      }
      final seek = _seekPositions.remove(reel.episodeId);
      if (seek != null) await controller.seekTo(seek);
      await controller.setLooping(true);
      await controller.setPlaybackSpeed(speed.value);
      if (_disposed || !_window.contains(reel.episodeId)) {
        await controller.dispose();
        return;
      }
      slot.controller.value = controller;
      final player = controller;
      player.addListener(() => _track(reel.episodeId, player));
      if (!source.isLocal && language == 'en') unawaited(_cache(reel));
      _sync();
    } on Object {
      await controller?.dispose();
      slot.failed.value = true;
    } finally {
      slot.loading = false;
      final latest = _reels[reel.episodeId];
      if (latest != null &&
          (_revision(latest) != _revision(reel) ||
              _language(latest.episodeId) != requestedLanguage) &&
          _window.contains(reel.episodeId)) {
        scheduleMicrotask(() => _load(latest));
      }
    }
  }

  String _language(String id) => _selectedLanguages[id] ?? 'en';

  String _revision(Reel reel) =>
      '${reel.videoRevision}:${(reel.videoVariants.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((entry) => '${entry.key}=${entry.value}').join('|')}';

  void _track(String id, VideoPlayerController controller) {
    final slot = _slots[id];
    if (slot == null || !controller.value.isPlaying) return;
    final seconds = controller.value.position.inSeconds;
    if (seconds > slot.furthest) slot.furthest = seconds;
    if (slot.furthest - slot.reported >= _reportEvery) _report(id);
    if (!slot.viewed &&
        _active &&
        id == _currentId &&
        controller.value.position >= _viewAfter) {
      slot.viewed = true;
      _onViewed(id);
    }
  }

  void _resetViewed(String? id) {
    if (id != null) _slots[id]?.viewed = false;
  }

  void _report(String? id) {
    final slot = id == null ? null : _slots[id];
    if (slot == null || slot.furthest < _minSeconds) return;
    if (slot.furthest == slot.reported) return;
    slot.reported = slot.furthest;
    unawaited(_onWatched(id!, slot.furthest));
  }

  void _unload(String id) {
    final slot = _slots[id];
    final old = slot?.controller.value;
    if (slot == null || old == null) return;
    slot.controller.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _sync() {
    _slots.forEach((id, slot) {
      final controller = slot.controller.value;
      if (controller == null || !controller.value.isInitialized) return;
      final shouldPlay = id == _currentId && _active && !_userPaused;
      if (shouldPlay && !controller.value.isPlaying) {
        unawaited(controller.play());
      } else if (!shouldPlay && controller.value.isPlaying) {
        unawaited(controller.pause());
      }
      if (id != _currentId && controller.value.position > Duration.zero) {
        unawaited(controller.seekTo(Duration.zero));
      }
    });
  }

  void dispose() {
    _report(_currentId);
    _onLeave();
    _disposed = true;
    for (final slot in _slots.values) {
      slot.controller.value?.dispose();
      slot.controller.dispose();
      slot.failed.dispose();
      slot.language.dispose();
    }
    speed.dispose();
  }
}
