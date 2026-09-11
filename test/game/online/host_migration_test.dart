import "package:flutter_test/flutter_test.dart";
import "package:tfi_bagundaali/game/online/host_migration.dart";
import "package:tfi_bagundaali/rooms/room_models.dart";

RoomSnapshot snapshot(
  Map<String, RoomPlayer> players, {
  String hostUid = "u1",
}) =>
    RoomSnapshot(
      code: "X",
      meta: RoomMeta(status: "playing", hostUid: hostUid, maxPlayers: 8),
      players: players,
      deckOrder: const [],
      centerIndex: 0,
      result: null,
    );

void main() {
  test("electedHost picks the earliest-joined connected player", () {
    final snap = snapshot({
      "u1": const RoomPlayer(
        name: "A",
        joinedAt: 500,
        connected: false,
        currentCardId: 0,
        count: 0,
      ),
      "u2": const RoomPlayer(
        name: "B",
        joinedAt: 200,
        connected: true,
        currentCardId: 0,
        count: 0,
      ),
      "u3": const RoomPlayer(
        name: "C",
        joinedAt: 300,
        connected: true,
        currentCardId: 0,
        count: 0,
      ),
    });
    expect(electedHost(snap), "u2");
  });

  test("electedHost is null when nobody is connected", () {
    final snap = snapshot({
      "u1": const RoomPlayer(
        name: "A",
        joinedAt: 500,
        connected: false,
        currentCardId: 0,
        count: 0,
      ),
    });
    expect(electedHost(snap), isNull);
  });

  test(
      "shouldIElectMyself is true only for the elected host when the "
      "current host dropped", () {
    final snap = snapshot(
      {
        "u1": const RoomPlayer(
          name: "A",
          joinedAt: 500,
          connected: false,
          currentCardId: 0,
          count: 0,
        ),
        "u2": const RoomPlayer(
          name: "B",
          joinedAt: 200,
          connected: true,
          currentCardId: 0,
          count: 0,
        ),
      },
    );
    expect(shouldIElectMyself(snap, "u2"), isTrue);
    expect(shouldIElectMyself(snap, "u1"), isFalse);
  });

  test("shouldIElectMyself is false while the current host is still connected",
      () {
    final snap = snapshot(
      {
        "u1": const RoomPlayer(
          name: "A",
          joinedAt: 500,
          connected: true,
          currentCardId: 0,
          count: 0,
        ),
        "u2": const RoomPlayer(
          name: "B",
          joinedAt: 200,
          connected: true,
          currentCardId: 0,
          count: 0,
        ),
      },
    );
    expect(shouldIElectMyself(snap, "u2"), isFalse);
  });
}
