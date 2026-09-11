import "package:flutter/foundation.dart";

@immutable
class RoomMeta {
  const RoomMeta({
    required this.status,
    required this.hostUid,
    required this.maxPlayers,
  });

  factory RoomMeta.fromMap(Map<Object?, Object?> map) => RoomMeta(
        status: map["status"] as String? ?? "lobby",
        hostUid: map["hostUid"] as String? ?? "",
        maxPlayers: (map["maxPlayers"] as num?)?.toInt() ?? 8,
      );

  static const empty = RoomMeta(status: "lobby", hostUid: "", maxPlayers: 8);

  final String status;
  final String hostUid;
  final int maxPlayers;

  Map<String, Object?> toMap() => {
        "status": status,
        "hostUid": hostUid,
        "maxPlayers": maxPlayers,
      };

  @override
  bool operator ==(Object other) =>
      other is RoomMeta &&
      other.status == status &&
      other.hostUid == hostUid &&
      other.maxPlayers == maxPlayers;

  @override
  int get hashCode => Object.hash(status, hostUid, maxPlayers);
}

@immutable
class RoomPlayer {
  const RoomPlayer({
    required this.name,
    required this.joinedAt,
    required this.connected,
    required this.currentCardId,
    required this.count,
  });

  factory RoomPlayer.fromMap(Map<Object?, Object?> map) => RoomPlayer(
        name: map["name"] as String? ?? "Player",
        joinedAt: (map["joinedAt"] as num?)?.toInt() ?? 0,
        connected: map["connected"] as bool? ?? false,
        currentCardId: (map["currentCardId"] as num?)?.toInt() ?? -1,
        count: (map["count"] as num?)?.toInt() ?? 0,
      );

  final String name;
  final int joinedAt;
  final bool connected;
  final int currentCardId;
  final int count;
}

@immutable
class RoomResult {
  const RoomResult({required this.winnerUid, required this.standings});

  factory RoomResult.fromMap(Map<Object?, Object?> map) => RoomResult(
        winnerUid: map["winnerUid"] as String?,
        standings: {
          for (final e in ((map["standings"] as Map?) ?? const {}).entries)
            e.key! as String: (e.value! as num).toInt(),
        },
      );

  final String? winnerUid;
  final Map<String, int> standings;
}

@immutable
class RoomSnapshot {
  const RoomSnapshot({
    required this.code,
    required this.meta,
    required this.players,
    required this.deckOrder,
    required this.centerIndex,
    required this.result,
  });

  factory RoomSnapshot.empty(String code) => RoomSnapshot(
        code: code,
        meta: RoomMeta.empty,
        players: const {},
        deckOrder: const [],
        centerIndex: 0,
        result: null,
      );

  factory RoomSnapshot.fromMap(String code, Map<Object?, Object?>? raw) {
    if (raw == null) return RoomSnapshot.empty(code);

    final metaMap = (raw["meta"] as Map?)?.cast<Object?, Object?>();
    final playersMap =
        (raw["players"] as Map?)?.cast<Object?, Object?>() ?? const {};
    final deckMap = (raw["deck"] as Map?)?.cast<Object?, Object?>();
    final resultMap = (raw["result"] as Map?)?.cast<Object?, Object?>();

    return RoomSnapshot(
      code: code,
      meta: metaMap == null ? RoomMeta.empty : RoomMeta.fromMap(metaMap),
      players: {
        for (final e in playersMap.entries)
          e.key! as String: RoomPlayer.fromMap((e.value! as Map).cast()),
      },
      deckOrder: ((deckMap?["order"] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      centerIndex: (deckMap?["centerIndex"] as num?)?.toInt() ?? 0,
      result: resultMap == null ? null : RoomResult.fromMap(resultMap),
    );
  }

  final String code;
  final RoomMeta meta;
  final Map<String, RoomPlayer> players;
  final List<int> deckOrder;
  final int centerIndex;
  final RoomResult? result;

  bool get exists => meta.hostUid.isNotEmpty;

  bool get isComplete =>
      deckOrder.isNotEmpty && centerIndex >= deckOrder.length;

  int get centerCardId => deckOrder[centerIndex];
}
