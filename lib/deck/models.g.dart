// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameSymbolImpl _$$GameSymbolImplFromJson(Map<String, dynamic> json) =>
    _$GameSymbolImpl(
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$$GameSymbolImplToJson(_$GameSymbolImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

_$GameCardImpl _$$GameCardImplFromJson(Map<String, dynamic> json) =>
    _$GameCardImpl(
      id: (json['id'] as num).toInt(),
      symbolIds: (json['symbolIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$GameCardImplToJson(_$GameCardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'symbolIds': instance.symbolIds,
    };

_$SymbolPlacementImpl _$$SymbolPlacementImplFromJson(
        Map<String, dynamic> json) =>
    _$SymbolPlacementImpl(
      symbolId: (json['symbolId'] as num).toInt(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      scale: (json['scale'] as num).toDouble(),
      rotationTurns: (json['rotationTurns'] as num).toDouble(),
    );

Map<String, dynamic> _$$SymbolPlacementImplToJson(
        _$SymbolPlacementImpl instance) =>
    <String, dynamic>{
      'symbolId': instance.symbolId,
      'x': instance.x,
      'y': instance.y,
      'scale': instance.scale,
      'rotationTurns': instance.rotationTurns,
    };
