part of 'navigation_cubit.dart';

class NavigationState {
  const NavigationState({
    this.currentIndex = 0,
    this.showExitDialog = false,
  });

  final int currentIndex;
  final bool showExitDialog;

  NavigationState copyWith({int? currentIndex, bool? showExitDialog}) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      showExitDialog: showExitDialog ?? this.showExitDialog,
    );
  }
}
