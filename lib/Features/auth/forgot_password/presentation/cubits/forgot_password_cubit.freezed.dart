// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForgotPasswordState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState()';
}


}

/// @nodoc
class $ForgotPasswordStateCopyWith<$Res>  {
$ForgotPasswordStateCopyWith(ForgotPasswordState _, $Res Function(ForgotPasswordState) __);
}


/// Adds pattern-matching-related methods to [ForgotPasswordState].
extension ForgotPasswordStatePatterns on ForgotPasswordState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ForgotPasswordInitial value)?  initial,TResult Function( ForgotPasswordLoading value)?  loading,TResult Function( ForgotPasswordCodeSent value)?  codeSent,TResult Function( ForgotPasswordSuccess value)?  success,TResult Function( ForgotPasswordError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ForgotPasswordInitial() when initial != null:
return initial(_that);case ForgotPasswordLoading() when loading != null:
return loading(_that);case ForgotPasswordCodeSent() when codeSent != null:
return codeSent(_that);case ForgotPasswordSuccess() when success != null:
return success(_that);case ForgotPasswordError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ForgotPasswordInitial value)  initial,required TResult Function( ForgotPasswordLoading value)  loading,required TResult Function( ForgotPasswordCodeSent value)  codeSent,required TResult Function( ForgotPasswordSuccess value)  success,required TResult Function( ForgotPasswordError value)  error,}){
final _that = this;
switch (_that) {
case ForgotPasswordInitial():
return initial(_that);case ForgotPasswordLoading():
return loading(_that);case ForgotPasswordCodeSent():
return codeSent(_that);case ForgotPasswordSuccess():
return success(_that);case ForgotPasswordError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ForgotPasswordInitial value)?  initial,TResult? Function( ForgotPasswordLoading value)?  loading,TResult? Function( ForgotPasswordCodeSent value)?  codeSent,TResult? Function( ForgotPasswordSuccess value)?  success,TResult? Function( ForgotPasswordError value)?  error,}){
final _that = this;
switch (_that) {
case ForgotPasswordInitial() when initial != null:
return initial(_that);case ForgotPasswordLoading() when loading != null:
return loading(_that);case ForgotPasswordCodeSent() when codeSent != null:
return codeSent(_that);case ForgotPasswordSuccess() when success != null:
return success(_that);case ForgotPasswordError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  codeSent,TResult Function()?  success,TResult Function( String errorMessage)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ForgotPasswordInitial() when initial != null:
return initial();case ForgotPasswordLoading() when loading != null:
return loading();case ForgotPasswordCodeSent() when codeSent != null:
return codeSent();case ForgotPasswordSuccess() when success != null:
return success();case ForgotPasswordError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  codeSent,required TResult Function()  success,required TResult Function( String errorMessage)  error,}) {final _that = this;
switch (_that) {
case ForgotPasswordInitial():
return initial();case ForgotPasswordLoading():
return loading();case ForgotPasswordCodeSent():
return codeSent();case ForgotPasswordSuccess():
return success();case ForgotPasswordError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  codeSent,TResult? Function()?  success,TResult? Function( String errorMessage)?  error,}) {final _that = this;
switch (_that) {
case ForgotPasswordInitial() when initial != null:
return initial();case ForgotPasswordLoading() when loading != null:
return loading();case ForgotPasswordCodeSent() when codeSent != null:
return codeSent();case ForgotPasswordSuccess() when success != null:
return success();case ForgotPasswordError() when error != null:
return error(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class ForgotPasswordInitial implements ForgotPasswordState {
  const ForgotPasswordInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.initial()';
}


}




/// @nodoc


class ForgotPasswordLoading implements ForgotPasswordState {
  const ForgotPasswordLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.loading()';
}


}




/// @nodoc


class ForgotPasswordCodeSent implements ForgotPasswordState {
  const ForgotPasswordCodeSent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordCodeSent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.codeSent()';
}


}




/// @nodoc


class ForgotPasswordSuccess implements ForgotPasswordState {
  const ForgotPasswordSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.success()';
}


}




/// @nodoc


class ForgotPasswordError implements ForgotPasswordState {
  const ForgotPasswordError({required this.errorMessage});
  

 final  String errorMessage;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordErrorCopyWith<ForgotPasswordError> get copyWith => _$ForgotPasswordErrorCopyWithImpl<ForgotPasswordError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordError&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'ForgotPasswordState.error(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordErrorCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $ForgotPasswordErrorCopyWith(ForgotPasswordError value, $Res Function(ForgotPasswordError) _then) = _$ForgotPasswordErrorCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$ForgotPasswordErrorCopyWithImpl<$Res>
    implements $ForgotPasswordErrorCopyWith<$Res> {
  _$ForgotPasswordErrorCopyWithImpl(this._self, this._then);

  final ForgotPasswordError _self;
  final $Res Function(ForgotPasswordError) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(ForgotPasswordError(
errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
