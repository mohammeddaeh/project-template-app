// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'navigation_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NavigationState {

/// التبويبات الظاهرة — بالحالة لا بجانبها، فتبدّلُها يعيد البناء بنفسه.
 List<NavItem> get items; int get currentIndex; bool get showExitDialog;
/// Create a copy of NavigationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NavigationStateCopyWith<NavigationState> get copyWith => _$NavigationStateCopyWithImpl<NavigationState>(this as NavigationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NavigationState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.showExitDialog, showExitDialog) || other.showExitDialog == showExitDialog));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),currentIndex,showExitDialog);

@override
String toString() {
  return 'NavigationState(items: $items, currentIndex: $currentIndex, showExitDialog: $showExitDialog)';
}


}

/// @nodoc
abstract mixin class $NavigationStateCopyWith<$Res>  {
  factory $NavigationStateCopyWith(NavigationState value, $Res Function(NavigationState) _then) = _$NavigationStateCopyWithImpl;
@useResult
$Res call({
 List<NavItem> items, int currentIndex, bool showExitDialog
});




}
/// @nodoc
class _$NavigationStateCopyWithImpl<$Res>
    implements $NavigationStateCopyWith<$Res> {
  _$NavigationStateCopyWithImpl(this._self, this._then);

  final NavigationState _self;
  final $Res Function(NavigationState) _then;

/// Create a copy of NavigationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? currentIndex = null,Object? showExitDialog = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NavItem>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,showExitDialog: null == showExitDialog ? _self.showExitDialog : showExitDialog // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NavigationState].
extension NavigationStatePatterns on NavigationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NavigationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NavigationState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NavigationState value)  $default,){
final _that = this;
switch (_that) {
case _NavigationState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NavigationState value)?  $default,){
final _that = this;
switch (_that) {
case _NavigationState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NavItem> items,  int currentIndex,  bool showExitDialog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NavigationState() when $default != null:
return $default(_that.items,_that.currentIndex,_that.showExitDialog);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NavItem> items,  int currentIndex,  bool showExitDialog)  $default,) {final _that = this;
switch (_that) {
case _NavigationState():
return $default(_that.items,_that.currentIndex,_that.showExitDialog);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NavItem> items,  int currentIndex,  bool showExitDialog)?  $default,) {final _that = this;
switch (_that) {
case _NavigationState() when $default != null:
return $default(_that.items,_that.currentIndex,_that.showExitDialog);case _:
  return null;

}
}

}

/// @nodoc


class _NavigationState implements NavigationState {
  const _NavigationState({final  List<NavItem> items = const <NavItem>[], this.currentIndex = 0, this.showExitDialog = false}): _items = items;
  

/// التبويبات الظاهرة — بالحالة لا بجانبها، فتبدّلُها يعيد البناء بنفسه.
 final  List<NavItem> _items;
/// التبويبات الظاهرة — بالحالة لا بجانبها، فتبدّلُها يعيد البناء بنفسه.
@override@JsonKey() List<NavItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int currentIndex;
@override@JsonKey() final  bool showExitDialog;

/// Create a copy of NavigationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NavigationStateCopyWith<_NavigationState> get copyWith => __$NavigationStateCopyWithImpl<_NavigationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NavigationState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.showExitDialog, showExitDialog) || other.showExitDialog == showExitDialog));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),currentIndex,showExitDialog);

@override
String toString() {
  return 'NavigationState(items: $items, currentIndex: $currentIndex, showExitDialog: $showExitDialog)';
}


}

/// @nodoc
abstract mixin class _$NavigationStateCopyWith<$Res> implements $NavigationStateCopyWith<$Res> {
  factory _$NavigationStateCopyWith(_NavigationState value, $Res Function(_NavigationState) _then) = __$NavigationStateCopyWithImpl;
@override @useResult
$Res call({
 List<NavItem> items, int currentIndex, bool showExitDialog
});




}
/// @nodoc
class __$NavigationStateCopyWithImpl<$Res>
    implements _$NavigationStateCopyWith<$Res> {
  __$NavigationStateCopyWithImpl(this._self, this._then);

  final _NavigationState _self;
  final $Res Function(_NavigationState) _then;

/// Create a copy of NavigationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? currentIndex = null,Object? showExitDialog = null,}) {
  return _then(_NavigationState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NavItem>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,showExitDialog: null == showExitDialog ? _self.showExitDialog : showExitDialog // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
