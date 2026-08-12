// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_form_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NoteFormState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteFormState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NoteFormState()';
}


}

/// @nodoc
class $NoteFormStateCopyWith<$Res>  {
$NoteFormStateCopyWith(NoteFormState _, $Res Function(NoteFormState) __);
}


/// Adds pattern-matching-related methods to [NoteFormState].
extension NoteFormStatePatterns on NoteFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NoteFormInitial value)?  initial,TResult Function( NoteFormLoading value)?  loading,TResult Function( NoteFormSuccess value)?  success,TResult Function( NoteFormError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NoteFormInitial() when initial != null:
return initial(_that);case NoteFormLoading() when loading != null:
return loading(_that);case NoteFormSuccess() when success != null:
return success(_that);case NoteFormError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NoteFormInitial value)  initial,required TResult Function( NoteFormLoading value)  loading,required TResult Function( NoteFormSuccess value)  success,required TResult Function( NoteFormError value)  error,}){
final _that = this;
switch (_that) {
case NoteFormInitial():
return initial(_that);case NoteFormLoading():
return loading(_that);case NoteFormSuccess():
return success(_that);case NoteFormError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NoteFormInitial value)?  initial,TResult? Function( NoteFormLoading value)?  loading,TResult? Function( NoteFormSuccess value)?  success,TResult? Function( NoteFormError value)?  error,}){
final _that = this;
switch (_that) {
case NoteFormInitial() when initial != null:
return initial(_that);case NoteFormLoading() when loading != null:
return loading(_that);case NoteFormSuccess() when success != null:
return success(_that);case NoteFormError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Note note,  bool isNew)?  success,TResult Function( String errorMessage)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NoteFormInitial() when initial != null:
return initial();case NoteFormLoading() when loading != null:
return loading();case NoteFormSuccess() when success != null:
return success(_that.note,_that.isNew);case NoteFormError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Note note,  bool isNew)  success,required TResult Function( String errorMessage)  error,}) {final _that = this;
switch (_that) {
case NoteFormInitial():
return initial();case NoteFormLoading():
return loading();case NoteFormSuccess():
return success(_that.note,_that.isNew);case NoteFormError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Note note,  bool isNew)?  success,TResult? Function( String errorMessage)?  error,}) {final _that = this;
switch (_that) {
case NoteFormInitial() when initial != null:
return initial();case NoteFormLoading() when loading != null:
return loading();case NoteFormSuccess() when success != null:
return success(_that.note,_that.isNew);case NoteFormError() when error != null:
return error(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class NoteFormInitial implements NoteFormState {
  const NoteFormInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteFormInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NoteFormState.initial()';
}


}




/// @nodoc


class NoteFormLoading implements NoteFormState {
  const NoteFormLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteFormLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NoteFormState.loading()';
}


}




/// @nodoc


class NoteFormSuccess implements NoteFormState {
  const NoteFormSuccess({required this.note, required this.isNew});
  

 final  Note note;
 final  bool isNew;

/// Create a copy of NoteFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteFormSuccessCopyWith<NoteFormSuccess> get copyWith => _$NoteFormSuccessCopyWithImpl<NoteFormSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteFormSuccess&&(identical(other.note, note) || other.note == note)&&(identical(other.isNew, isNew) || other.isNew == isNew));
}


@override
int get hashCode => Object.hash(runtimeType,note,isNew);

@override
String toString() {
  return 'NoteFormState.success(note: $note, isNew: $isNew)';
}


}

/// @nodoc
abstract mixin class $NoteFormSuccessCopyWith<$Res> implements $NoteFormStateCopyWith<$Res> {
  factory $NoteFormSuccessCopyWith(NoteFormSuccess value, $Res Function(NoteFormSuccess) _then) = _$NoteFormSuccessCopyWithImpl;
@useResult
$Res call({
 Note note, bool isNew
});




}
/// @nodoc
class _$NoteFormSuccessCopyWithImpl<$Res>
    implements $NoteFormSuccessCopyWith<$Res> {
  _$NoteFormSuccessCopyWithImpl(this._self, this._then);

  final NoteFormSuccess _self;
  final $Res Function(NoteFormSuccess) _then;

/// Create a copy of NoteFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? note = null,Object? isNew = null,}) {
  return _then(NoteFormSuccess(
note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as Note,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class NoteFormError implements NoteFormState {
  const NoteFormError({required this.errorMessage});
  

 final  String errorMessage;

/// Create a copy of NoteFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteFormErrorCopyWith<NoteFormError> get copyWith => _$NoteFormErrorCopyWithImpl<NoteFormError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteFormError&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'NoteFormState.error(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $NoteFormErrorCopyWith<$Res> implements $NoteFormStateCopyWith<$Res> {
  factory $NoteFormErrorCopyWith(NoteFormError value, $Res Function(NoteFormError) _then) = _$NoteFormErrorCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$NoteFormErrorCopyWithImpl<$Res>
    implements $NoteFormErrorCopyWith<$Res> {
  _$NoteFormErrorCopyWithImpl(this._self, this._then);

  final NoteFormError _self;
  final $Res Function(NoteFormError) _then;

/// Create a copy of NoteFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(NoteFormError(
errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
