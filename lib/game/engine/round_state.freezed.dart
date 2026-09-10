// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'round_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RoundState {
  List<int> get deckOrder => throw _privateConstructorUsedError;
  int get centerIndex => throw _privateConstructorUsedError;
  int get heldCardId => throw _privateConstructorUsedError;
  int get collected => throw _privateConstructorUsedError;

  /// Create a copy of RoundState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoundStateCopyWith<RoundState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoundStateCopyWith<$Res> {
  factory $RoundStateCopyWith(
          RoundState value, $Res Function(RoundState) then) =
      _$RoundStateCopyWithImpl<$Res, RoundState>;
  @useResult
  $Res call(
      {List<int> deckOrder, int centerIndex, int heldCardId, int collected});
}

/// @nodoc
class _$RoundStateCopyWithImpl<$Res, $Val extends RoundState>
    implements $RoundStateCopyWith<$Res> {
  _$RoundStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoundState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deckOrder = null,
    Object? centerIndex = null,
    Object? heldCardId = null,
    Object? collected = null,
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
      heldCardId: null == heldCardId
          ? _value.heldCardId
          : heldCardId // ignore: cast_nullable_to_non_nullable
              as int,
      collected: null == collected
          ? _value.collected
          : collected // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoundStateImplCopyWith<$Res>
    implements $RoundStateCopyWith<$Res> {
  factory _$$RoundStateImplCopyWith(
          _$RoundStateImpl value, $Res Function(_$RoundStateImpl) then) =
      __$$RoundStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<int> deckOrder, int centerIndex, int heldCardId, int collected});
}

/// @nodoc
class __$$RoundStateImplCopyWithImpl<$Res>
    extends _$RoundStateCopyWithImpl<$Res, _$RoundStateImpl>
    implements _$$RoundStateImplCopyWith<$Res> {
  __$$RoundStateImplCopyWithImpl(
      _$RoundStateImpl _value, $Res Function(_$RoundStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoundState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deckOrder = null,
    Object? centerIndex = null,
    Object? heldCardId = null,
    Object? collected = null,
  }) {
    return _then(_$RoundStateImpl(
      deckOrder: null == deckOrder
          ? _value._deckOrder
          : deckOrder // ignore: cast_nullable_to_non_nullable
              as List<int>,
      centerIndex: null == centerIndex
          ? _value.centerIndex
          : centerIndex // ignore: cast_nullable_to_non_nullable
              as int,
      heldCardId: null == heldCardId
          ? _value.heldCardId
          : heldCardId // ignore: cast_nullable_to_non_nullable
              as int,
      collected: null == collected
          ? _value.collected
          : collected // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$RoundStateImpl implements _RoundState {
  const _$RoundStateImpl(
      {required final List<int> deckOrder,
      required this.centerIndex,
      required this.heldCardId,
      required this.collected})
      : _deckOrder = deckOrder;

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
  final int heldCardId;
  @override
  final int collected;

  @override
  String toString() {
    return 'RoundState(deckOrder: $deckOrder, centerIndex: $centerIndex, heldCardId: $heldCardId, collected: $collected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoundStateImpl &&
            const DeepCollectionEquality()
                .equals(other._deckOrder, _deckOrder) &&
            (identical(other.centerIndex, centerIndex) ||
                other.centerIndex == centerIndex) &&
            (identical(other.heldCardId, heldCardId) ||
                other.heldCardId == heldCardId) &&
            (identical(other.collected, collected) ||
                other.collected == collected));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_deckOrder),
      centerIndex,
      heldCardId,
      collected);

  /// Create a copy of RoundState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoundStateImplCopyWith<_$RoundStateImpl> get copyWith =>
      __$$RoundStateImplCopyWithImpl<_$RoundStateImpl>(this, _$identity);
}

abstract class _RoundState implements RoundState {
  const factory _RoundState(
      {required final List<int> deckOrder,
      required final int centerIndex,
      required final int heldCardId,
      required final int collected}) = _$RoundStateImpl;

  @override
  List<int> get deckOrder;
  @override
  int get centerIndex;
  @override
  int get heldCardId;
  @override
  int get collected;

  /// Create a copy of RoundState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoundStateImplCopyWith<_$RoundStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
