part of 'refresh_cubit.dart';

/// No equality, on purpose: every `emit(RefreshState())` must rebuild. With
/// `@freezed` two instances compare equal and the cubit drops the emit (R05).
class RefreshState {}
