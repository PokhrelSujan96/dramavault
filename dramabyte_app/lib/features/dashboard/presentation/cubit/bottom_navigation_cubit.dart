import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bottom_navigation_state.dart';

class BottomNavCubit extends Cubit<BottomNavState> {
  BottomNavCubit() : super(const BottomNavInitial());

  int get currentIndex => state.index;

  void changeTab(int index) {
    if (index < 0 || index >= 4 || index == currentIndex) return;
    HapticFeedback.lightImpact();
    emit(BottomNavChanged(index));
  }

  void resetToHome() => changeTab(0);
}
