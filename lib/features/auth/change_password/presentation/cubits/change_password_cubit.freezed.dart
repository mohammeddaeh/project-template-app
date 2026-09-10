// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'change_password_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChangePasswordState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePasswordState()';
}


}

/// @nodoc
class $ChangePasswordStateCopyWith<$Res>  {
$ChangePasswordStateCopyWith(ChangePasswordState _, $Res Function(ChangePasswordState) __);
}


/// Adds pattern-matching-related methods to [ChangePasswordState].
extension ChangePasswordStatePatterns on ChangePasswordState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChangePasswordInitial value)?  initial,TResult Function( ChangePasswordLoading value)?  loading,TResult Function( ChangePasswordSuccess value)?  success,TResult Function( ChangePasswordError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChangePasswordInitial() when initial != null:
return initial(_that);case ChangePasswordLoading() when loading != null:
return loading(_that);case ChangePasswordSuccess() when success != null:
return success(_that);case ChangePasswordError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChangePasswordInitial value)  initial,required TResult Function( ChangePasswordLoading value)  loading,required TResult Function( ChangePasswordSuccess value)  success,required TResult Function( ChangePasswordError value)  error,}){
final _that = this;
switch (_that) {
case ChangePasswordInitial():
return initial(_that);case ChangePasswordLoading():
return loading(_that);case ChangePasswordSuccess():
return success(_that);case ChangePasswordError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChangePasswordInitial value)?  initial,TResult? Function( ChangePasswordLoading value)?  loading,TResult? Function( ChangePasswordSuccess value)?  success,TResult? Function( ChangePasswordError value)?  error,}){
final _that = this;
switch (_that) {
case ChangePasswordInitial() when initial != null:
return initial(_that);case ChangePasswordLoading() when loading != null:
return loading(_that);case ChangePasswordSuccess() when success != null:
return success(_that);case ChangePasswordError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  success,TResult Function( String errorMessage)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChangePasswordInitial() when initial != null:
return initial();case ChangePasswordLoading() when loading != null:
return loading();case ChangePasswordSuccess() when success != null:
return success();case ChangePasswordError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  success,required TResult Function( String errorMessage)  error,}) {final _that = this;
switch (_that) {
case ChangePasswordInitial():
return initial();case ChangePasswordLoading():
return loading();case ChangePasswordSuccess():
return success();case ChangePasswordError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  success,TResult? Function( String errorMessage)?  error,}) {final _that = this;
switch (_that) {
case ChangePasswordInitial() when initial != null:
return initial();case ChangePasswordLoading() when loading != null:
return loading();case ChangePasswordSuccess() when success != null:
return success();case ChangePasswordError() when error != null:
return error(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class ChangePasswordInitial implements ChangePasswordState {
  const ChangePasswordInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePasswordState.initial()';
}


}




/// @nodoc


class ChangePasswordLoading implements ChangePasswordState {
  const ChangePasswordLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePasswordState.loading()';
}


}




/// @nodoc


class ChangePasswordSuccess implements ChangePasswordState {
  const ChangePasswordSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePasswordState.success()';
}


}




/// @nodoc


class ChangePasswordError implements ChangePasswordState {
  const ChangePasswordError({required this.errorMessage});
  

 final  String errorMessage;

/// Create a copy of ChangePasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangePasswordErrorCopyWith<ChangePasswordError> get copyWith => _$ChangePasswordErrorCopyWithImpl<ChangePasswordError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordError&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'ChangePasswordState.error(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ChangePasswordErrorCopyWith<$Res> implements $ChangePasswordStateCopyWith<$Res> {
  factory $ChangePasswordErrorCopyWith(ChangePasswordError value, $Res Function(ChangePasswordError) _then) = _$ChangePasswordErrorCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$ChangePasswordErrorCopyWithImpl<$Res>
    implements $ChangePasswordErrorCopyWith<$Res> {
  _$ChangePasswordErrorCopyWithImpl(this._self, this._then);

  final ChangePasswordError _self;
  final $Res Function(ChangePasswordError) _then;

/// Create a copy of ChangePasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(ChangePasswordError(
errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
