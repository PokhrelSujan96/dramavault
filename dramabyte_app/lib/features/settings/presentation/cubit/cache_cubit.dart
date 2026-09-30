import 'package:dramabyte_app/features/settings/domain/repositories/cache_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class CacheState extends Equatable {
  const CacheState({this.bytes, this.clearing = false});

  final int? bytes;
  final bool clearing;

  @override
  List<Object?> get props => [bytes, clearing];
}

final class CacheCubit extends Cubit<CacheState> {
  CacheCubit(this._repository) : super(const CacheState());

  final CacheRepository _repository;

  Future<void> measure() async {
    try {
      emit(CacheState(bytes: await _repository.size()));
    } on Object {
      emit(const CacheState(bytes: 0));
    }
  }

  Future<void> clear() async {
    emit(CacheState(bytes: state.bytes, clearing: true));
    try {
      await _repository.clear();
    } finally {
      await measure();
    }
  }
}
