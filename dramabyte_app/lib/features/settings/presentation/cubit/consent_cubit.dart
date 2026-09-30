import 'package:dramabyte_app/features/settings/domain/entities/consent_preferences.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/consent_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class ConsentState extends Equatable {
  const ConsentState({
    this.preferences = const ConsentPreferences(),
    this.offline = false,
  });

  final ConsentPreferences preferences;
  final bool offline;

  @override
  List<Object> get props => [preferences, offline];
}

final class ConsentCubit extends Cubit<ConsentState> {
  ConsentCubit(this._repository) : super(const ConsentState());

  final ConsentRepository _repository;

  Future<void> load() async {
    final stored = await _repository.stored();
    if (stored == null) return _adoptRemote();
    emit(ConsentState(preferences: stored.preferences));
    if (stored.pending) await _push(stored.preferences);
  }

  Future<void> set(ConsentPurpose purpose, bool granted) async {
    final next = state.preferences.copyWithPurpose(purpose, granted);
    emit(ConsentState(preferences: next));
    await _repository.store(next, pending: true);
    await _push(next);
  }

  Future<void> _adoptRemote() async {
    final remote = await _repository.fetch();
    emit(ConsentState(preferences: remote ?? const ConsentPreferences()));
    if (remote != null) await _repository.store(remote, pending: false);
  }

  Future<void> _push(ConsentPreferences preferences) async {
    final synced = await _repository.push(preferences);
    if (!isClosed && state.preferences == preferences) {
      emit(ConsentState(preferences: preferences, offline: !synced));
    }
  }
}
