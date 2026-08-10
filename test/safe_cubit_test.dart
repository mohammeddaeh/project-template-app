import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/foundation/domain/safe_cubit.dart';

/// The crash this exists to stop, reproduced and then prevented.
///
/// A request outlives its screen — the reader taps back, a sheet closes, a
/// `ListView` disposes a section — and the response lands on a closed cubit.
/// Plain `Cubit.emit` throws `StateError` there, in release as well as debug,
/// which turns "left the screen quickly" into a crash.
void main() {
  test('plain Cubit throws when a late response lands', () async {
    final cubit = _PlainCubit();
    final inFlight = cubit.load(); // starts, does not finish
    await cubit.close();

    // Documents the failure mode rather than asserting a library detail: if
    // bloc ever stops throwing here, SafeCubit becomes unnecessary and this
    // test says so out loud instead of quietly passing.
    expect(inFlight, throwsStateError);
  });

  test('SafeCubit drops it instead', () async {
    final cubit = _SafeCubit();
    final inFlight = cubit.load();
    await cubit.close();

    await expectLater(inFlight, completes);
    // The state never moved past what it held when it closed — the late answer
    // is discarded, not applied to a cubit nobody is listening to.
    expect(cubit.state, 0);
  });
}

class _PlainCubit extends Cubit<int> {
  _PlainCubit() : super(0);

  Future<void> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    emit(1);
  }
}

class _SafeCubit extends SafeCubit<int> {
  _SafeCubit() : super(0);

  Future<void> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    emit(1);
  }
}
