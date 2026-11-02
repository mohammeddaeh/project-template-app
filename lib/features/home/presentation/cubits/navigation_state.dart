part of 'navigation_cubit.dart';

@freezed
abstract class NavigationState with _$NavigationState {
  const factory NavigationState({
    /// التبويبات الظاهرة — بالحالة لا بجانبها، فتبدّلُها يعيد البناء بنفسه.
    @Default(<NavItem>[]) List<NavItem> items,
    @Default(0) int currentIndex,
    @Default(false) bool showExitDialog,
  }) = _NavigationState;
}
