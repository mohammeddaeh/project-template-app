// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verify_email_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VerifyEmailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyEmailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyEmailState()';
}


}

/// @nodoc
class $VerifyEmailStateCopyWith<$Res>  {
$VerifyEmailStateCopyWith(VerifyEmailState _, $Res Function(VerifyEmailState) __);
}


/// Adds pattern-matching-related methods to [VerifyEmailState].
extension VerifyEmailStatePatterns on VerifyEmailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VerifyEmailInitial value)?  initial,TResult Function( VerifyEmailLoading value)?  loading,TResult Function( VerifyEmailVerified value)?  verified,TResult Function( VerifyEmailCodeResent value)?  codeResent,TResult Function( VerifyEmailCooldownTick value)?  cooldownTick,TResult Function( VerifyEmailError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VerifyEmailInitial() when initial != null:
return initial(_that);case VerifyEmailLoading() when loading != null:
return loading(_that);case VerifyEmailVerified() when verified != null:
return verified(_that);case VerifyEmailCodeResent() when codeResent != null:
return codeResent(_that);case VerifyEmailCooldownTick() when cooldownTick != null:
return cooldownTick(_that);case VerifyEmailError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VerifyEmailInitial value)  initial,required TResult Function( VerifyEmailLoading value)  loading,required TResult Function( VerifyEmailVerified value)  verified,required TResult Function( VerifyEmailCodeResent value)  codeResent,required TResult Function( VerifyEmailCooldownTick value)  cooldownTick,required TResult Function( VerifyEmailError value)  error,}){
final _that = this;
switch (_that) {
case VerifyEmailInitial():
return initial(_that);case VerifyEmailLoading():
return loading(_that);case VerifyEmailVerified():
return verified(_that);case VerifyEmailCodeResent():
return codeResent(_that);case VerifyEmailCooldownTick():
return cooldownTick(_that);case VerifyEmailError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VerifyEmailInitial value)?  initial,TResult? Function( VerifyEmailLoading value)?  loading,TResult? Function( VerifyEmailVerified value)?  verified,TResult? Function( VerifyEmailCodeResent value)?  codeResent,TResult? Function( VerifyEmailCooldownTick value)?  cooldownTick,TResult? Function( VerifyEmailError value)?  error,}){
final _that = this;
switch (_that) {
case VerifyEmailInitial() when initial != null:
return initial(_that);case VerifyEmailLoading() when loading != null:
return loading(_that);case VerifyEmailVerified() when verified != null:
return verified(_that);case VerifyEmailCodeResent() when codeResent != null:
return codeResent(_that);case VerifyEmailCooldownTick() when cooldownTick != null:
return cooldownTick(_that);case VerifyEmailError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( AuthUser user)?  verified,TResult Function()?  codeResent,TResult Function( int secondsLeft)?  cooldownTick,TResult Function( String errorMessage)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VerifyEmailInitial() when initial != null:
return initial();case VerifyEmailLoading() when loading != null:
return loading();case VerifyEmailVerified() when verified != null:
return verified(_that.user);case VerifyEmailCodeResent() when codeResent != null:
return codeResent();case VerifyEmailCooldownTick() when cooldownTick != null:
return cooldownTick(_that.secondsLeft);case VerifyEmailError() when error != null:
return error(_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( AuthUser user)  verified,required TResult Function()  codeResent,required TResult Function( int secondsLeft)  cooldownTick,required TResult Function( String errorMessage)  error,}) {final _that = this;
switch (_that) {
case VerifyEmailInitial():
return initial();case VerifyEmailLoading():
return loading();case VerifyEmailVerified():
return verified(_that.user);case VerifyEmailCodeResent():
return codeResent();case VerifyEmailCooldownTick():
return cooldownTick(_that.secondsLeft);case VerifyEmailError():
return error(_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( AuthUser user)?  verified,TResult? Function()?  codeResent,TResult? Function( int secondsLeft)?  cooldownTick,TResult? Function( String errorMessage)?  error,}) {final _that = this;
switch (_that) {
case VerifyEmailInitial() when initial != null:
return initial();case VerifyEmailLoading() when loading != null:
return loading();case VerifyEmailVerified() when verified != null:
return verified(_that.user);case VerifyEmailCodeResent() when codeResent != null:
return codeResent();case VerifyEmailCooldownTick() when cooldownTick != null:
return cooldownTick(_that.secondsLeft);case VerifyEmailError() when error != null:
return error(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class VerifyEmailInitial implements VerifyEmailState {
  const VerifyEmailInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyEmailInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyEmailState.initial()';
}


}




/// @nodoc


class VerifyEmailLoading implements VerifyEmailState {
  const VerifyEmailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyEmailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyEmailState.loading()';
}


}




/// @nodoc


class VerifyEmailVerified implements VerifyEmailState {
  const VerifyEmailVerified({required this.user});
  

 final  AuthUser user;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyEmailVerifiedCopyWith<VerifyEmailVerified> get copyWith => _$VerifyEmailVerifiedCopyWithImpl<VerifyEmailVerified>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyEmailVerified&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'VerifyEmailState.verified(user: $user)';
}


}

/// @nodoc
abstract mixin class $VerifyEmailVerifiedCopyWith<$Res> implements $VerifyEmailStateCopyWith<$Res> {
  factory $VerifyEmailVerifiedCopyWith(VerifyEmailVerified value, $Res Function(VerifyEmailVerified) _then) = _$VerifyEmailVerifiedCopyWithImpl;
@useResult
$Res call({
 AuthUser user
});




}
/// @nodoc
class _$VerifyEmailVerifiedCopyWithImpl<$Res>
    implements $VerifyEmailVerifiedCopyWith<$Res> {
  _$VerifyEmailVerifiedCopyWithImpl(this._self, this._then);

  final VerifyEmailVerified _self;
  final $Res Function(VerifyEmailVerified) _then;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(VerifyEmailVerified(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser,
  ));
}


}

/// @nodoc


class VerifyEmailCodeResent implements VerifyEmailState {
  const VerifyEmailCodeResent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyEmailCodeResent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyEmailState.codeResent()';
}


}




/// @nodoc


class VerifyEmailCooldownTick implements VerifyEmailState {
  const VerifyEmailCooldownTick({required this.secondsLeft});
  

 final  int secondsLeft;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyEmailCooldownTickCopyWith<VerifyEmailCooldownTick> get copyWith => _$VerifyEmailCooldownTickCopyWithImpl<VerifyEmailCooldownTick>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyEmailCooldownTick&&(identical(other.secondsLeft, secondsLeft) || other.secondsLeft == secondsLeft));
}


@override
int get hashCode => Object.hash(runtimeType,secondsLeft);

@override
String toString() {
  return 'VerifyEmailState.cooldownTick(secondsLeft: $secondsLeft)';
}


}

/// @nodoc
abstract mixin class $VerifyEmailCooldownTickCopyWith<$Res> implements $VerifyEmailStateCopyWith<$Res> {
  factory $VerifyEmailCooldownTickCopyWith(VerifyEmailCooldownTick value, $Res Function(VerifyEmailCooldownTick) _then) = _$VerifyEmailCooldownTickCopyWithImpl;
@useResult
$Res call({
 int secondsLeft
});




}
/// @nodoc
class _$VerifyEmailCooldownTickCopyWithImpl<$Res>
    implements $VerifyEmailCooldownTickCopyWith<$Res> {
  _$VerifyEmailCooldownTickCopyWithImpl(this._self, this._then);

  final VerifyEmailCooldownTick _self;
  final $Res Function(VerifyEmailCooldownTick) _then;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? secondsLeft = null,}) {
  return _then(VerifyEmailCooldownTick(
secondsLeft: null == secondsLeft ? _self.secondsLeft : secondsLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class VerifyEmailError implements VerifyEmailState {
  const VerifyEmailError({required this.errorMessage});
  

 final  String errorMessage;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyEmailErrorCopyWith<VerifyEmailError> get copyWith => _$VerifyEmailErrorCopyWithImpl<VerifyEmailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyEmailError&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'VerifyEmailState.error(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $VerifyEmailErrorCopyWith<$Res> implements $VerifyEmailStateCopyWith<$Res> {
  factory $VerifyEmailErrorCopyWith(VerifyEmailError value, $Res Function(VerifyEmailError) _then) = _$VerifyEmailErrorCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$VerifyEmailErrorCopyWithImpl<$Res>
    implements $VerifyEmailErrorCopyWith<$Res> {
  _$VerifyEmailErrorCopyWithImpl(this._self, this._then);

  final VerifyEmailError _self;
  final $Res Function(VerifyEmailError) _then;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(VerifyEmailError(
errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
