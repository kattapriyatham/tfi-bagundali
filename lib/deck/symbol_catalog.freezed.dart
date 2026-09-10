// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'symbol_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SymbolArt {
  SymbolShape get shape => throw _privateConstructorUsedError;
  int get colorValue => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;

  /// Create a copy of SymbolArt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SymbolArtCopyWith<SymbolArt> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SymbolArtCopyWith<$Res> {
  factory $SymbolArtCopyWith(SymbolArt value, $Res Function(SymbolArt) then) =
      _$SymbolArtCopyWithImpl<$Res, SymbolArt>;
  @useResult
  $Res call({SymbolShape shape, int colorValue, String label});
}

/// @nodoc
class _$SymbolArtCopyWithImpl<$Res, $Val extends SymbolArt>
    implements $SymbolArtCopyWith<$Res> {
  _$SymbolArtCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SymbolArt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shape = null,
    Object? colorValue = null,
    Object? label = null,
  }) {
    return _then(_value.copyWith(
      shape: null == shape
          ? _value.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as SymbolShape,
      colorValue: null == colorValue
          ? _value.colorValue
          : colorValue // ignore: cast_nullable_to_non_nullable
              as int,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SymbolArtImplCopyWith<$Res>
    implements $SymbolArtCopyWith<$Res> {
  factory _$$SymbolArtImplCopyWith(
          _$SymbolArtImpl value, $Res Function(_$SymbolArtImpl) then) =
      __$$SymbolArtImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SymbolShape shape, int colorValue, String label});
}

/// @nodoc
class __$$SymbolArtImplCopyWithImpl<$Res>
    extends _$SymbolArtCopyWithImpl<$Res, _$SymbolArtImpl>
    implements _$$SymbolArtImplCopyWith<$Res> {
  __$$SymbolArtImplCopyWithImpl(
      _$SymbolArtImpl _value, $Res Function(_$SymbolArtImpl) _then)
      : super(_value, _then);

  /// Create a copy of SymbolArt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shape = null,
    Object? colorValue = null,
    Object? label = null,
  }) {
    return _then(_$SymbolArtImpl(
      shape: null == shape
          ? _value.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as SymbolShape,
      colorValue: null == colorValue
          ? _value.colorValue
          : colorValue // ignore: cast_nullable_to_non_nullable
              as int,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SymbolArtImpl implements _SymbolArt {
  const _$SymbolArtImpl(
      {required this.shape, required this.colorValue, required this.label});

  @override
  final SymbolShape shape;
  @override
  final int colorValue;
  @override
  final String label;

  @override
  String toString() {
    return 'SymbolArt(shape: $shape, colorValue: $colorValue, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SymbolArtImpl &&
            (identical(other.shape, shape) || other.shape == shape) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue) &&
            (identical(other.label, label) || other.label == label));
  }

  @override
  int get hashCode => Object.hash(runtimeType, shape, colorValue, label);

  /// Create a copy of SymbolArt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SymbolArtImplCopyWith<_$SymbolArtImpl> get copyWith =>
      __$$SymbolArtImplCopyWithImpl<_$SymbolArtImpl>(this, _$identity);
}

abstract class _SymbolArt implements SymbolArt {
  const factory _SymbolArt(
      {required final SymbolShape shape,
      required final int colorValue,
      required final String label}) = _$SymbolArtImpl;

  @override
  SymbolShape get shape;
  @override
  int get colorValue;
  @override
  String get label;

  /// Create a copy of SymbolArt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SymbolArtImplCopyWith<_$SymbolArtImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
