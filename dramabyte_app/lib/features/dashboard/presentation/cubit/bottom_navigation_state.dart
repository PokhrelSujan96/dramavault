import 'package:equatable/equatable.dart';

sealed class BottomNavState extends Equatable {
  const BottomNavState(this.index);

  final int index;

  @override
  List<Object> get props => [index];
}

final class BottomNavInitial extends BottomNavState {
  const BottomNavInitial() : super(0);
}

final class BottomNavChanged extends BottomNavState {
  const BottomNavChanged(super.index);
}
