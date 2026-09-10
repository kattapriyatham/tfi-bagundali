// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameSymbol _$GameSymbolFromJson(Map<String, dynamic> json) {
  return _GameSymbol.fromJson(json);
}

/// @nodoc
mixin _$GameSymbol {
  int get id => throw _privateConstructorUsedError;

  /// Serializes this GameSymbol to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameSymbol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameSymbolCopyWith<GameSymbol> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameSymbolCopyWith<$Res> {
  factory $GameSymbolCopyWith(
          GameSymbol value, $Res Function(GameSymbol) then) =
      _$GameSymbolCopyWithImpl<$Res, GameSymbol>;
  @useResult
  $Res call({int id});
}

/// @nodoc
class _$GameSymbolCopyWithImpl<$Res, $Val extends GameSymbol>
    implements $GameSymbolCopyWith<$Res> {
  _$GameSymbolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameSymbol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameSymbolImplCopyWith<$Res>
    implements $GameSymbolCopyWith<$Res> {
  factory _$$GameSymbolImplCopyWith(
          _$GameSymbolImpl value, $Res Function(_$GameSymbolImpl) then) =
      __$$GameSymbolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id});
}

/// @nodoc
class __$$GameSymbolImplCopyWithImpl<$Res>
    extends _$GameSymbolCopyWithImpl<$Res, _$GameSymbolImpl>
    implements _$$GameSymbolImplCopyWith<$Res> {
  __$$GameSymbolImplCopyWithImpl(
      _$GameSymbolImpl _value, $Res Function(_$GameSymbolImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameSymbol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_$GameSymbolImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameSymbolImpl implements _GameSymbol {
  const _$GameSymbolImpl({required this.id});

  factory _$GameSymbolImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameSymbolImplFromJson(json);

  @override
  final int id;

  @override
  String toString() {
    return 'GameSymbol(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameSymbolImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id);

  /// Create a copy of GameSymbol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameSymbolImplCopyWith<_$GameSymbolImpl> get copyWith =>
      __$$GameSymbolImplCopyWithImpl<_$GameSymbolImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameSymbolImplToJson(
      this,
    );
  }
}

abstract class _GameSymbol implements GameSymbol {
  const factory _GameSymbol({required final int id}) = _$GameSymbolImpl;

  factory _GameSymbol.fromJson(Map<String, dynamic> json) =
      _$GameSymbolImpl.fromJson;

  @override
  int get id;

  /// Create a copy of GameSymbol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameSymbolImplCopyWith<_$GameSymbolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameCard _$GameCardFromJson(Map<String, dynamic> json) {
  return _GameCard.fromJson(json);
}

/// @nodoc
mixin _$GameCard {
  int get id => throw _privateConstructorUsedError;
  List<int> get symbolIds => throw _privateConstructorUsedError;

  /// Serializes this GameCard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameCardCopyWith<GameCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameCardCopyWith<$Res> {
  factory $GameCardCopyWith(GameCard value, $Res Function(GameCard) then) =
      _$GameCardCopyWithImpl<$Res, GameCard>;
  @useResult
  $Res call({int id, List<int> symbolIds});
}

/// @nodoc
class _$GameCardCopyWithImpl<$Res, $Val extends GameCard>
    implements $GameCardCopyWith<$Res> {
  _$GameCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbolIds = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      symbolIds: null == symbolIds
          ? _value.symbolIds
          : symbolIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameCardImplCopyWith<$Res>
    implements $GameCardCopyWith<$Res> {
  factory _$$GameCardImplCopyWith(
          _$GameCardImpl value, $Res Function(_$GameCardImpl) then) =
      __$$GameCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, List<int> symbolIds});
}

/// @nodoc
class __$$GameCardImplCopyWithImpl<$Res>
    extends _$GameCardCopyWithImpl<$Res, _$GameCardImpl>
    implements _$$GameCardImplCopyWith<$Res> {
  __$$GameCardImplCopyWithImpl(
      _$GameCardImpl _value, $Res Function(_$GameCardImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbolIds = null,
  }) {
    return _then(_$GameCardImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      symbolIds: null == symbolIds
          ? _value._symbolIds
          : symbolIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameCardImpl implements _GameCard {
  const _$GameCardImpl({required this.id, required final List<int> symbolIds})
      : _symbolIds = symbolIds;

  factory _$GameCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameCardImplFromJson(json);

  @override
  final int id;
  final List<int> _symbolIds;
  @override
  List<int> get symbolIds {
    if (_symbolIds is EqualUnmodifiableListView) return _symbolIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_symbolIds);
  }

  @override
  String toString() {
    return 'GameCard(id: $id, symbolIds: $symbolIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameCardImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._symbolIds, _symbolIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, const DeepCollectionEquality().hash(_symbolIds));

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameCardImplCopyWith<_$GameCardImpl> get copyWith =>
      __$$GameCardImplCopyWithImpl<_$GameCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameCardImplToJson(
      this,
    );
  }
}

abstract class _GameCard implements GameCard {
  const factory _GameCard(
      {required final int id,
      required final List<int> symbolIds}) = _$GameCardImpl;

  factory _GameCard.fromJson(Map<String, dynamic> json) =
      _$GameCardImpl.fromJson;

  @override
  int get id;
  @override
  List<int> get symbolIds;

  /// Create a copy of GameCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameCardImplCopyWith<_$GameCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SymbolPlacement _$SymbolPlacementFromJson(Map<String, dynamic> json) {
  return _SymbolPlacement.fromJson(json);
}

/// @nodoc
mixin _$SymbolPlacement {
  int get symbolId => throw _privateConstructorUsedError;
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;
  double get scale => throw _privateConstructorUsedError;
  double get rotationTurns => throw _privateConstructorUsedError;

  /// Serializes this SymbolPlacement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SymbolPlacement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SymbolPlacementCopyWith<SymbolPlacement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SymbolPlacementCopyWith<$Res> {
  factory $SymbolPlacementCopyWith(
          SymbolPlacement value, $Res Function(SymbolPlacement) then) =
      _$SymbolPlacementCopyWithImpl<$Res, SymbolPlacement>;
  @useResult
  $Res call(
      {int symbolId, double x, double y, double scale, double rotationTurns});
}

/// @nodoc
class _$SymbolPlacementCopyWithImpl<$Res, $Val extends SymbolPlacement>
    implements $SymbolPlacementCopyWith<$Res> {
  _$SymbolPlacementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SymbolPlacement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbolId = null,
    Object? x = null,
    Object? y = null,
    Object? scale = null,
    Object? rotationTurns = null,
  }) {
    return _then(_value.copyWith(
      symbolId: null == symbolId
          ? _value.symbolId
          : symbolId // ignore: cast_nullable_to_non_nullable
              as int,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      scale: null == scale
          ? _value.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
      rotationTurns: null == rotationTurns
          ? _value.rotationTurns
          : rotationTurns // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SymbolPlacementImplCopyWith<$Res>
    implements $SymbolPlacementCopyWith<$Res> {
  factory _$$SymbolPlacementImplCopyWith(_$SymbolPlacementImpl value,
          $Res Function(_$SymbolPlacementImpl) then) =
      __$$SymbolPlacementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int symbolId, double x, double y, double scale, double rotationTurns});
}

/// @nodoc
class __$$SymbolPlacementImplCopyWithImpl<$Res>
    extends _$SymbolPlacementCopyWithImpl<$Res, _$SymbolPlacementImpl>
    implements _$$SymbolPlacementImplCopyWith<$Res> {
  __$$SymbolPlacementImplCopyWithImpl(
      _$SymbolPlacementImpl _value, $Res Function(_$SymbolPlacementImpl) _then)
      : super(_value, _then);

  /// Create a copy of SymbolPlacement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbolId = null,
    Object? x = null,
    Object? y = null,
    Object? scale = null,
    Object? rotationTurns = null,
  }) {
    return _then(_$SymbolPlacementImpl(
      symbolId: null == symbolId
          ? _value.symbolId
          : symbolId // ignore: cast_nullable_to_non_nullable
              as int,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      scale: null == scale
          ? _value.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
      rotationTurns: null == rotationTurns
          ? _value.rotationTurns
          : rotationTurns // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SymbolPlacementImpl implements _SymbolPlacement {
  const _$SymbolPlacementImpl(
      {required this.symbolId,
      required this.x,
      required this.y,
      required this.scale,
      required this.rotationTurns});

  factory _$SymbolPlacementImpl.fromJson(Map<String, dynamic> json) =>
      _$$SymbolPlacementImplFromJson(json);

  @override
  final int symbolId;
  @override
  final double x;
  @override
  final double y;
  @override
  final double scale;
  @override
  final double rotationTurns;

  @override
  String toString() {
    return 'SymbolPlacement(symbolId: $symbolId, x: $x, y: $y, scale: $scale, rotationTurns: $rotationTurns)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SymbolPlacementImpl &&
            (identical(other.symbolId, symbolId) ||
                other.symbolId == symbolId) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.scale, scale) || other.scale == scale) &&
            (identical(other.rotationTurns, rotationTurns) ||
                other.rotationTurns == rotationTurns));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, symbolId, x, y, scale, rotationTurns);

  /// Create a copy of SymbolPlacement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SymbolPlacementImplCopyWith<_$SymbolPlacementImpl> get copyWith =>
      __$$SymbolPlacementImplCopyWithImpl<_$SymbolPlacementImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SymbolPlacementImplToJson(
      this,
    );
  }
}

abstract class _SymbolPlacement implements SymbolPlacement {
  const factory _SymbolPlacement(
      {required final int symbolId,
      required final double x,
      required final double y,
      required final double scale,
      required final double rotationTurns}) = _$SymbolPlacementImpl;

  factory _SymbolPlacement.fromJson(Map<String, dynamic> json) =
      _$SymbolPlacementImpl.fromJson;

  @override
  int get symbolId;
  @override
  double get x;
  @override
  double get y;
  @override
  double get scale;
  @override
  double get rotationTurns;

  /// Create a copy of SymbolPlacement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SymbolPlacementImplCopyWith<_$SymbolPlacementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
