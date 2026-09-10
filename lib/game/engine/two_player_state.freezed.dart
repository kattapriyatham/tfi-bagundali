// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'two_player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TwoPlayerState {
  List<int> get deckOrder => throw _privateConstructorUsedError;
  int get centerIndex => throw _privateConstructorUsedError;
  int get heldP1 => throw _privateConstructorUsedError;
  int get heldP2 => throw _privateConstructorUsedError;
  int get countP1 => throw _privateConstructorUsedError;
  int get countP2 => throw _privateConstructorUsedError;

  /// Create a copy of TwoPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TwoPlayerStateCopyWith<TwoPlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TwoPlayerStateCopyWith<$Res> {
  factory $TwoPlayerStateCopyWith(
          TwoPlayerState value, $Res Function(TwoPlayerState) then) =
      _$TwoPlayerStateCopyWithImpl<$Res, TwoPlayerState>;
  @useResult
  $Res call(
      {List<int> deckOrder,
      int centerIndex,
      int heldP1,
      int heldP2,
      int countP1,
      int countP2});
}

/// @nodoc
class _$TwoPlayerStateCopyWithImpl<$Res, $Val extends TwoPlayerState>
    implements $TwoPlayerStateCopyWith<$Res> {
  _$TwoPlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TwoPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deckOrder = null,
    Object? centerIndex = null,
    Object? heldP1 = null,
    Object? heldP2 = null,
    Object? countP1 = null,
    Object? countP2 = null,
  }) {
    return _then(_value.copyWith(
      deckOrder: null == deckOrder
          ? _value.deckOrder
          : deckOrder // ignore: cast_nullable_to_non_nullable
              as List<int>,
      centerIndex: null == centerIndex
          ? _value.centerIndex
          : centerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      heldP1: null == heldP1
          ? _value.heldP1
          : heldP1 // ignore: cast_nullable_to_non_nullable
              as int,
      heldP2: null == heldP2
          ? _value.heldP2
          : heldP2 // ignore: cast_nullable_to_non_nullable
              as int,
      countP1: null == countP1
          ? _value.countP1
          : countP1 // ignore: cast_nullable_to_non_nullable
              as int,
      countP2: null == countP2
          ? _value.countP2
          : countP2 // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TwoPlayerStateImplCopyWith<$Res>
    implements $TwoPlayerStateCopyWith<$Res> {
  factory _$$TwoPlayerStateImplCopyWith(_$TwoPlayerStateImpl value,
          $Res Function(_$TwoPlayerStateImpl) then) =
      __$$TwoPlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<int> deckOrder,
      int centerIndex,
      int heldP1,
      int heldP2,
      int countP1,
      int countP2});
}

/// @nodoc
class __$$TwoPlayerStateImplCopyWithImpl<$Res>
    extends _$TwoPlayerStateCopyWithImpl<$Res, _$TwoPlayerStateImpl>
    implements _$$TwoPlayerStateImplCopyWith<$Res> {
  __$$TwoPlayerStateImplCopyWithImpl(
      _$TwoPlayerStateImpl _value, $Res Function(_$TwoPlayerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TwoPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deckOrder = null,
    Object? centerIndex = null,
    Object? heldP1 = null,
    Object? heldP2 = null,
    Object? countP1 = null,
    Object? countP2 = null,
  }) {
    return _then(_$TwoPlayerStateImpl(
      deckOrder: null == deckOrder
          ? _value._deckOrder
          : deckOrder // ignore: cast_nullable_to_non_nullable
              as List<int>,
      centerIndex: null == centerIndex
          ? _value.centerIndex
          : centerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      heldP1: null == heldP1
          ? _value.heldP1
          : heldP1 // ignore: cast_nullable_to_non_nullable
              as int,
      heldP2: null == heldP2
          ? _value.heldP2
          : heldP2 // ignore: cast_nullable_to_non_nullable
              as int,
      countP1: null == countP1
          ? _value.countP1
          : countP1 // ignore: cast_nullable_to_non_nullable
              as int,
      countP2: null == countP2
          ? _value.countP2
          : countP2 // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$TwoPlayerStateImpl extends _TwoPlayerState {
  const _$TwoPlayerStateImpl(
      {required final List<int> deckOrder,
      required this.centerIndex,
      required this.heldP1,
      required this.heldP2,
      required this.countP1,
      required this.countP2})
      : _deckOrder = deckOrder,
        super._();

  final List<int> _deckOrder;
  @override
  List<int> get deckOrder {
    if (_deckOrder is EqualUnmodifiableListView) return _deckOrder;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deckOrder);
  }

  @override
  final int centerIndex;
  @override
  final int heldP1;
  @override
  final int heldP2;
  @override
  final int countP1;
  @override
  final int countP2;

  @override
  String toString() {
    return 'TwoPlayerState(deckOrder: $deckOrder, centerIndex: $centerIndex, heldP1: $heldP1, heldP2: $heldP2, countP1: $countP1, countP2: $countP2)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TwoPlayerStateImpl &&
            const DeepCollectionEquality()
                .equals(other._deckOrder, _deckOrder) &&
            (identical(other.centerIndex, centerIndex) ||
                other.centerIndex == centerIndex) &&
            (identical(other.heldP1, heldP1) || other.heldP1 == heldP1) &&
            (identical(other.heldP2, heldP2) || other.heldP2 == heldP2) &&
            (identical(other.countP1, countP1) || other.countP1 == countP1) &&
            (identical(other.countP2, countP2) || other.countP2 == countP2));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_deckOrder),
      centerIndex,
      heldP1,
      heldP2,
      countP1,
      countP2);

  /// Create a copy of TwoPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TwoPlayerStateImplCopyWith<_$TwoPlayerStateImpl> get copyWith =>
      __$$TwoPlayerStateImplCopyWithImpl<_$TwoPlayerStateImpl>(
          this, _$identity);
}

abstract class _TwoPlayerState extends TwoPlayerState {
  const factory _TwoPlayerState(
      {required final List<int> deckOrder,
      required final int centerIndex,
      required final int heldP1,
      required final int heldP2,
      required final int countP1,
      required final int countP2}) = _$TwoPlayerStateImpl;
  const _TwoPlayerState._() : super._();

  @override
  List<int> get deckOrder;
  @override
  int get centerIndex;
  @override
  int get heldP1;
  @override
  int get heldP2;
  @override
  int get countP1;
  @override
  int get countP2;

  /// Create a copy of TwoPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TwoPlayerStateImplCopyWith<_$TwoPlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
