// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'logout_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LogoutState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogoutState()';
}


}

/// @nodoc
class $LogoutStateCopyWith<$Res>  {
$LogoutStateCopyWith(LogoutState _, $Res Function(LogoutState) __);
}


/// Adds pattern-matching-related methods to [LogoutState].
extension LogoutStatePatterns on LogoutState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LogoutInitial value)?  initial,TResult Function( LogoutLoading value)?  loading,TResult Function( LogoutSuccess value)?  success,TResult Function( LogoutError value)?  error,TResult Function( LogoutPendingWork value)?  pendingWork,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LogoutInitial() when initial != null:
return initial(_that);case LogoutLoading() when loading != null:
return loading(_that);case LogoutSuccess() when success != null:
return success(_that);case LogoutError() when error != null:
return error(_that);case LogoutPendingWork() when pendingWork != null:
return pendingWork(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LogoutInitial value)  initial,required TResult Function( LogoutLoading value)  loading,required TResult Function( LogoutSuccess value)  success,required TResult Function( LogoutError value)  error,required TResult Function( LogoutPendingWork value)  pendingWork,}){
final _that = this;
switch (_that) {
case LogoutInitial():
return initial(_that);case LogoutLoading():
return loading(_that);case LogoutSuccess():
return success(_that);case LogoutError():
return error(_that);case LogoutPendingWork():
return pendingWork(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LogoutInitial value)?  initial,TResult? Function( LogoutLoading value)?  loading,TResult? Function( LogoutSuccess value)?  success,TResult? Function( LogoutError value)?  error,TResult? Function( LogoutPendingWork value)?  pendingWork,}){
final _that = this;
switch (_that) {
case LogoutInitial() when initial != null:
return initial(_that);case LogoutLoading() when loading != null:
return loading(_that);case LogoutSuccess() when success != null:
return success(_that);case LogoutError() when error != null:
return error(_that);case LogoutPendingWork() when pendingWork != null:
return pendingWork(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  success,TResult Function( String errorMessage)?  error,TResult Function( int pendingOperations)?  pendingWork,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LogoutInitial() when initial != null:
return initial();case LogoutLoading() when loading != null:
return loading();case LogoutSuccess() when success != null:
return success();case LogoutError() when error != null:
return error(_that.errorMessage);case LogoutPendingWork() when pendingWork != null:
return pendingWork(_that.pendingOperations);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  success,required TResult Function( String errorMessage)  error,required TResult Function( int pendingOperations)  pendingWork,}) {final _that = this;
switch (_that) {
case LogoutInitial():
return initial();case LogoutLoading():
return loading();case LogoutSuccess():
return success();case LogoutError():
return error(_that.errorMessage);case LogoutPendingWork():
return pendingWork(_that.pendingOperations);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  success,TResult? Function( String errorMessage)?  error,TResult? Function( int pendingOperations)?  pendingWork,}) {final _that = this;
switch (_that) {
case LogoutInitial() when initial != null:
return initial();case LogoutLoading() when loading != null:
return loading();case LogoutSuccess() when success != null:
return success();case LogoutError() when error != null:
return error(_that.errorMessage);case LogoutPendingWork() when pendingWork != null:
return pendingWork(_that.pendingOperations);case _:
  return null;

}
}

}

/// @nodoc


class LogoutInitial implements LogoutState {
  const LogoutInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogoutState.initial()';
}


}




/// @nodoc


class LogoutLoading implements LogoutState {
  const LogoutLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogoutState.loading()';
}


}




/// @nodoc


class LogoutSuccess implements LogoutState {
  const LogoutSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogoutState.success()';
}


}




/// @nodoc


class LogoutError implements LogoutState {
  const LogoutError({required this.errorMessage});
  

 final  String errorMessage;

/// Create a copy of LogoutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoutErrorCopyWith<LogoutError> get copyWith => _$LogoutErrorCopyWithImpl<LogoutError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutError&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'LogoutState.error(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $LogoutErrorCopyWith<$Res> implements $LogoutStateCopyWith<$Res> {
  factory $LogoutErrorCopyWith(LogoutError value, $Res Function(LogoutError) _then) = _$LogoutErrorCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$LogoutErrorCopyWithImpl<$Res>
    implements $LogoutErrorCopyWith<$Res> {
  _$LogoutErrorCopyWithImpl(this._self, this._then);

  final LogoutError _self;
  final $Res Function(LogoutError) _then;

/// Create a copy of LogoutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(LogoutError(
errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LogoutPendingWork implements LogoutState {
  const LogoutPendingWork({required this.pendingOperations});
  

 final  int pendingOperations;

/// Create a copy of LogoutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoutPendingWorkCopyWith<LogoutPendingWork> get copyWith => _$LogoutPendingWorkCopyWithImpl<LogoutPendingWork>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutPendingWork&&(identical(other.pendingOperations, pendingOperations) || other.pendingOperations == pendingOperations));
}


@override
int get hashCode => Object.hash(runtimeType,pendingOperations);

@override
String toString() {
  return 'LogoutState.pendingWork(pendingOperations: $pendingOperations)';
}


}

/// @nodoc
abstract mixin class $LogoutPendingWorkCopyWith<$Res> implements $LogoutStateCopyWith<$Res> {
  factory $LogoutPendingWorkCopyWith(LogoutPendingWork value, $Res Function(LogoutPendingWork) _then) = _$LogoutPendingWorkCopyWithImpl;
@useResult
$Res call({
 int pendingOperations
});




}
/// @nodoc
class _$LogoutPendingWorkCopyWithImpl<$Res>
    implements $LogoutPendingWorkCopyWith<$Res> {
  _$LogoutPendingWorkCopyWithImpl(this._self, this._then);

  final LogoutPendingWork _self;
  final $Res Function(LogoutPendingWork) _then;

/// Create a copy of LogoutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pendingOperations = null,}) {
  return _then(LogoutPendingWork(
pendingOperations: null == pendingOperations ? _self.pendingOperations : pendingOperations // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
