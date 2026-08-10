import 'package:app_template/core/foundation/domain/safe_cubit.dart';
import 'package:app_template/shared/widgets/navigation/nav_item.dart';
import 'package:injectable/injectable.dart';

part 'navigation_state.dart';

@lazySingleton
class NavigationCubit extends SafeCubit<NavigationState> {
  NavigationCubit() : super(const NavigationState());

  List<NavItem> _items = [];

  List<NavItem> get visibleItems => _items;

  void setItems(List<NavItem> items) {
    _items = items;
    emit(state.copyWith(currentIndex: 0));
  }

  void onItemTapped(int index) {
    if (index == state.currentIndex) return;
    emit(state.copyWith(currentIndex: index));
  }

  void onBackPressed() {
    if (state.currentIndex != 0) {
      emit(state.copyWith(currentIndex: 0));
      return;
    }
    emit(state.copyWith(showExitDialog: true));
  }

  void confirmExit() => emit(state.copyWith(showExitDialog: false));

  void dismissExitDialog() => emit(state.copyWith(showExitDialog: false));
}
