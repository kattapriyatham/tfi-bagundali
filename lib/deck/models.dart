import "package:freezed_annotation/freezed_annotation.dart";

part "models.freezed.dart";
part "models.g.dart";

@freezed
class GameSymbol with _$GameSymbol {
  const factory GameSymbol({required int id}) = _GameSymbol;
  factory GameSymbol.fromJson(Map<String, dynamic> json) =>
      _$GameSymbolFromJson(json);
}

@freezed
class GameCard with _$GameCard {
  const factory GameCard({
    required int id,
    required List<int> symbolIds,
  }) = _GameCard;
  factory GameCard.fromJson(Map<String, dynamic> json) =>
      _$GameCardFromJson(json);
}

@freezed
class SymbolPlacement with _$SymbolPlacement {
  const factory SymbolPlacement({
    required int symbolId,
    required double x,
    required double y,
    required double scale,
    required double rotationTurns,
  }) = _SymbolPlacement;
  factory SymbolPlacement.fromJson(Map<String, dynamic> json) =>
      _$SymbolPlacementFromJson(json);
}
