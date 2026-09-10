import 'package:app_template/core/foundation/domain/safe_cubit.dart';

part 'refresh_state.dart';

/// Lightweight cubit used to trigger a rebuild of a widget subtree.
/// Create directly with `RefreshCubit()` — not via DI.
/// Call [refresh] to emit a new state and force dependent widgets to rebuild.
class RefreshCubit extends SafeCubit<RefreshState> {
  RefreshCubit() : super(RefreshState());

  void refresh() {
    emit(RefreshState());
  }
}
