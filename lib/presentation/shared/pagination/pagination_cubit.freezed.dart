// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pagination_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaginationState<E> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationState<E>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaginationState<$E>()';
}


}

/// @nodoc
class $PaginationStateCopyWith<E,$Res>  {
$PaginationStateCopyWith(PaginationState<E> _, $Res Function(PaginationState<E>) __);
}


/// Adds pattern-matching-related methods to [PaginationState].
extension PaginationStatePatterns<E> on PaginationState<E> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PaginationLoadingState<E> value)?  loading,TResult Function( PaginationErrorState<E> value)?  error,TResult Function( PaginationInitState<E> value)?  initial,TResult Function( PaginationSuccessState<E> value)?  success,TResult Function( PaginationEmptyState<E> value)?  emptyData,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PaginationLoadingState() when loading != null:
return loading(_that);case PaginationErrorState() when error != null:
return error(_that);case PaginationInitState() when initial != null:
return initial(_that);case PaginationSuccessState() when success != null:
return success(_that);case PaginationEmptyState() when emptyData != null:
return emptyData(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PaginationLoadingState<E> value)  loading,required TResult Function( PaginationErrorState<E> value)  error,required TResult Function( PaginationInitState<E> value)  initial,required TResult Function( PaginationSuccessState<E> value)  success,required TResult Function( PaginationEmptyState<E> value)  emptyData,}){
final _that = this;
switch (_that) {
case PaginationLoadingState():
return loading(_that);case PaginationErrorState():
return error(_that);case PaginationInitState():
return initial(_that);case PaginationSuccessState():
return success(_that);case PaginationEmptyState():
return emptyData(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PaginationLoadingState<E> value)?  loading,TResult? Function( PaginationErrorState<E> value)?  error,TResult? Function( PaginationInitState<E> value)?  initial,TResult? Function( PaginationSuccessState<E> value)?  success,TResult? Function( PaginationEmptyState<E> value)?  emptyData,}){
final _that = this;
switch (_that) {
case PaginationLoadingState() when loading != null:
return loading(_that);case PaginationErrorState() when error != null:
return error(_that);case PaginationInitState() when initial != null:
return initial(_that);case PaginationSuccessState() when success != null:
return success(_that);case PaginationEmptyState() when emptyData != null:
return emptyData(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Failure? error)?  error,TResult Function()?  initial,TResult Function( PaginationDataEntity<E> paginationEntity,  bool isLoading,  Failure? error)?  success,TResult Function()?  emptyData,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PaginationLoadingState() when loading != null:
return loading();case PaginationErrorState() when error != null:
return error(_that.error);case PaginationInitState() when initial != null:
return initial();case PaginationSuccessState() when success != null:
return success(_that.paginationEntity,_that.isLoading,_that.error);case PaginationEmptyState() when emptyData != null:
return emptyData();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Failure? error)  error,required TResult Function()  initial,required TResult Function( PaginationDataEntity<E> paginationEntity,  bool isLoading,  Failure? error)  success,required TResult Function()  emptyData,}) {final _that = this;
switch (_that) {
case PaginationLoadingState():
return loading();case PaginationErrorState():
return error(_that.error);case PaginationInitState():
return initial();case PaginationSuccessState():
return success(_that.paginationEntity,_that.isLoading,_that.error);case PaginationEmptyState():
return emptyData();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Failure? error)?  error,TResult? Function()?  initial,TResult? Function( PaginationDataEntity<E> paginationEntity,  bool isLoading,  Failure? error)?  success,TResult? Function()?  emptyData,}) {final _that = this;
switch (_that) {
case PaginationLoadingState() when loading != null:
return loading();case PaginationErrorState() when error != null:
return error(_that.error);case PaginationInitState() when initial != null:
return initial();case PaginationSuccessState() when success != null:
return success(_that.paginationEntity,_that.isLoading,_that.error);case PaginationEmptyState() when emptyData != null:
return emptyData();case _:
  return null;

}
}

}

/// @nodoc


class PaginationLoadingState<E> extends PaginationState<E> {
  const PaginationLoadingState(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationLoadingState<E>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaginationState<$E>.loading()';
}


}




/// @nodoc


class PaginationErrorState<E> extends PaginationState<E> {
  const PaginationErrorState([this.error]): super._();
  

 final  Failure? error;

/// Create a copy of PaginationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginationErrorStateCopyWith<E, PaginationErrorState<E>> get copyWith => _$PaginationErrorStateCopyWithImpl<E, PaginationErrorState<E>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationErrorState<E>&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'PaginationState<$E>.error(error: $error)';
}


}

/// @nodoc
abstract mixin class $PaginationErrorStateCopyWith<E,$Res> implements $PaginationStateCopyWith<E, $Res> {
  factory $PaginationErrorStateCopyWith(PaginationErrorState<E> value, $Res Function(PaginationErrorState<E>) _then) = _$PaginationErrorStateCopyWithImpl;
@useResult
$Res call({
 Failure? error
});




}
/// @nodoc
class _$PaginationErrorStateCopyWithImpl<E,$Res>
    implements $PaginationErrorStateCopyWith<E, $Res> {
  _$PaginationErrorStateCopyWithImpl(this._self, this._then);

  final PaginationErrorState<E> _self;
  final $Res Function(PaginationErrorState<E>) _then;

/// Create a copy of PaginationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = freezed,}) {
  return _then(PaginationErrorState<E>(
freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

/// @nodoc


class PaginationInitState<E> extends PaginationState<E> {
  const PaginationInitState(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationInitState<E>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaginationState<$E>.initial()';
}


}




/// @nodoc


class PaginationSuccessState<E> extends PaginationState<E> {
  const PaginationSuccessState(this.paginationEntity, {this.isLoading = false, this.error}): super._();
  

 final  PaginationDataEntity<E> paginationEntity;
@JsonKey() final  bool isLoading;
 final  Failure? error;

/// Create a copy of PaginationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginationSuccessStateCopyWith<E, PaginationSuccessState<E>> get copyWith => _$PaginationSuccessStateCopyWithImpl<E, PaginationSuccessState<E>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationSuccessState<E>&&(identical(other.paginationEntity, paginationEntity) || other.paginationEntity == paginationEntity)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,paginationEntity,isLoading,error);

@override
String toString() {
  return 'PaginationState<$E>.success(paginationEntity: $paginationEntity, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class $PaginationSuccessStateCopyWith<E,$Res> implements $PaginationStateCopyWith<E, $Res> {
  factory $PaginationSuccessStateCopyWith(PaginationSuccessState<E> value, $Res Function(PaginationSuccessState<E>) _then) = _$PaginationSuccessStateCopyWithImpl;
@useResult
$Res call({
 PaginationDataEntity<E> paginationEntity, bool isLoading, Failure? error
});




}
/// @nodoc
class _$PaginationSuccessStateCopyWithImpl<E,$Res>
    implements $PaginationSuccessStateCopyWith<E, $Res> {
  _$PaginationSuccessStateCopyWithImpl(this._self, this._then);

  final PaginationSuccessState<E> _self;
  final $Res Function(PaginationSuccessState<E>) _then;

/// Create a copy of PaginationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? paginationEntity = null,Object? isLoading = null,Object? error = freezed,}) {
  return _then(PaginationSuccessState<E>(
null == paginationEntity ? _self.paginationEntity : paginationEntity // ignore: cast_nullable_to_non_nullable
as PaginationDataEntity<E>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

/// @nodoc


class PaginationEmptyState<E> extends PaginationState<E> {
  const PaginationEmptyState(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationEmptyState<E>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaginationState<$E>.emptyData()';
}


}




// dart format on
