// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_guard_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionGuardState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionGuardState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionGuardState()';
}


}

/// @nodoc
class $SessionGuardStateCopyWith<$Res>  {
$SessionGuardStateCopyWith(SessionGuardState _, $Res Function(SessionGuardState) __);
}


/// Adds pattern-matching-related methods to [SessionGuardState].
extension SessionGuardStatePatterns on SessionGuardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionGuardChecking value)?  checking,TResult Function( SessionGuardUnlocked value)?  unlocked,TResult Function( SessionGuardNeedsSetup value)?  needsSetup,TResult Function( SessionGuardLocked value)?  locked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionGuardChecking() when checking != null:
return checking(_that);case SessionGuardUnlocked() when unlocked != null:
return unlocked(_that);case SessionGuardNeedsSetup() when needsSetup != null:
return needsSetup(_that);case SessionGuardLocked() when locked != null:
return locked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionGuardChecking value)  checking,required TResult Function( SessionGuardUnlocked value)  unlocked,required TResult Function( SessionGuardNeedsSetup value)  needsSetup,required TResult Function( SessionGuardLocked value)  locked,}){
final _that = this;
switch (_that) {
case SessionGuardChecking():
return checking(_that);case SessionGuardUnlocked():
return unlocked(_that);case SessionGuardNeedsSetup():
return needsSetup(_that);case SessionGuardLocked():
return locked(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionGuardChecking value)?  checking,TResult? Function( SessionGuardUnlocked value)?  unlocked,TResult? Function( SessionGuardNeedsSetup value)?  needsSetup,TResult? Function( SessionGuardLocked value)?  locked,}){
final _that = this;
switch (_that) {
case SessionGuardChecking() when checking != null:
return checking(_that);case SessionGuardUnlocked() when unlocked != null:
return unlocked(_that);case SessionGuardNeedsSetup() when needsSetup != null:
return needsSetup(_that);case SessionGuardLocked() when locked != null:
return locked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  checking,TResult Function()?  unlocked,TResult Function()?  needsSetup,TResult Function( bool wrongAttempt)?  locked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionGuardChecking() when checking != null:
return checking();case SessionGuardUnlocked() when unlocked != null:
return unlocked();case SessionGuardNeedsSetup() when needsSetup != null:
return needsSetup();case SessionGuardLocked() when locked != null:
return locked(_that.wrongAttempt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  checking,required TResult Function()  unlocked,required TResult Function()  needsSetup,required TResult Function( bool wrongAttempt)  locked,}) {final _that = this;
switch (_that) {
case SessionGuardChecking():
return checking();case SessionGuardUnlocked():
return unlocked();case SessionGuardNeedsSetup():
return needsSetup();case SessionGuardLocked():
return locked(_that.wrongAttempt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  checking,TResult? Function()?  unlocked,TResult? Function()?  needsSetup,TResult? Function( bool wrongAttempt)?  locked,}) {final _that = this;
switch (_that) {
case SessionGuardChecking() when checking != null:
return checking();case SessionGuardUnlocked() when unlocked != null:
return unlocked();case SessionGuardNeedsSetup() when needsSetup != null:
return needsSetup();case SessionGuardLocked() when locked != null:
return locked(_that.wrongAttempt);case _:
  return null;

}
}

}

/// @nodoc


class SessionGuardChecking implements SessionGuardState {
  const SessionGuardChecking();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionGuardChecking);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionGuardState.checking()';
}


}




/// @nodoc


class SessionGuardUnlocked implements SessionGuardState {
  const SessionGuardUnlocked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionGuardUnlocked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionGuardState.unlocked()';
}


}




/// @nodoc


class SessionGuardNeedsSetup implements SessionGuardState {
  const SessionGuardNeedsSetup();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionGuardNeedsSetup);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionGuardState.needsSetup()';
}


}




/// @nodoc


class SessionGuardLocked implements SessionGuardState {
  const SessionGuardLocked({this.wrongAttempt = false});
  

@JsonKey() final  bool wrongAttempt;

/// Create a copy of SessionGuardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionGuardLockedCopyWith<SessionGuardLocked> get copyWith => _$SessionGuardLockedCopyWithImpl<SessionGuardLocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionGuardLocked&&(identical(other.wrongAttempt, wrongAttempt) || other.wrongAttempt == wrongAttempt));
}


@override
int get hashCode => Object.hash(runtimeType,wrongAttempt);

@override
String toString() {
  return 'SessionGuardState.locked(wrongAttempt: $wrongAttempt)';
}


}

/// @nodoc
abstract mixin class $SessionGuardLockedCopyWith<$Res> implements $SessionGuardStateCopyWith<$Res> {
  factory $SessionGuardLockedCopyWith(SessionGuardLocked value, $Res Function(SessionGuardLocked) _then) = _$SessionGuardLockedCopyWithImpl;
@useResult
$Res call({
 bool wrongAttempt
});




}
/// @nodoc
class _$SessionGuardLockedCopyWithImpl<$Res>
    implements $SessionGuardLockedCopyWith<$Res> {
  _$SessionGuardLockedCopyWithImpl(this._self, this._then);

  final SessionGuardLocked _self;
  final $Res Function(SessionGuardLocked) _then;

/// Create a copy of SessionGuardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? wrongAttempt = null,}) {
  return _then(SessionGuardLocked(
wrongAttempt: null == wrongAttempt ? _self.wrongAttempt : wrongAttempt // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
