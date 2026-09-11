import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/rooms/room_models.dart";

void main() {
  test("RoomSnapshot.empty has no host and an empty player map", () {
    final s = RoomSnapshot.empty("ABCDE");
    expect(s.exists, isFalse);
    expect(s.players, isEmpty);
    expect(s.code, "ABCDE");
  });

  test("RoomSnapshot.fromMap parses a full RTDB-shaped map", () {
    final raw = {
      "meta": {"status": "playing", "hostUid": "u1", "maxPlayers": 8},
      "players": {
        "u1": {
          "name": "Alice",
          "joinedAt": 1000,
          "connected": true,
          "currentCardId": 3,
          "count": 2,
        },
        "u2": {
          "name": "Bob",
          "joinedAt": 2000,
          "connected": false,
          "currentCardId": 7,
          "count": 1,
        },
      },
      "deck": {
        "order": [3, 7, 12, 5],
        "centerIndex": 2,
      },
    };

    final s = RoomSnapshot.fromMap("ABCDE", raw);
    expect(s.exists, isTrue);
    expect(s.meta.status, "playing");
    expect(s.meta.hostUid, "u1");
    expect(s.players["u1"]!.name, "Alice");
    expect(s.players["u1"]!.joinedAt, 1000);
    expect(s.players["u2"]!.connected, isFalse);
    expect(s.deckOrder, [3, 7, 12, 5]);
    expect(s.centerIndex, 2);
    expect(s.centerCardId, 12);
    expect(s.isComplete, isFalse);
    expect(s.result, isNull);
  });

  test("RoomSnapshot.isComplete when centerIndex reaches deck length", () {
    final raw = {
      "meta": {"status": "playing", "hostUid": "u1", "maxPlayers": 2},
      "players": <String, Object?>{},
      "deck": {
        "order": [1, 2],
        "centerIndex": 2,
      },
    };
    expect(RoomSnapshot.fromMap("X", raw).isComplete, isTrue);
  });

  test("RoomSnapshot.fromMap parses a result block", () {
    final raw = {
      "meta": {"status": "finished", "hostUid": "u1", "maxPlayers": 2},
      "players": <String, Object?>{},
      "deck": {"order": <int>[], "centerIndex": 0},
      "result": {
        "winnerUid": "u1",
        "standings": {"u1": 30, "u2": 27},
      },
    };
    final s = RoomSnapshot.fromMap("X", raw);
    expect(s.result!.winnerUid, "u1");
    expect(s.result!.standings, {"u1": 30, "u2": 27});
  });

  test("RoomMeta.toMap round-trips through fromMap", () {
    const meta = RoomMeta(status: "lobby", hostUid: "u1", maxPlayers: 6);
    expect(RoomMeta.fromMap(meta.toMap()), meta);
  });
}
