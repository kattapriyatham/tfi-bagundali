import "dart:math";

import "package:firebase_database/firebase_database.dart";

import "room_code.dart";
import "room_models.dart";

class RoomJoinException implements Exception {
  const RoomJoinException(this.message);
  final String message;
  @override
  String toString() => "RoomJoinException: $message";
}

class RoomCreateException implements Exception {
  const RoomCreateException(this.message);
  final String message;
  @override
  String toString() => "RoomCreateException: $message";
}

/// RTDB I/O for `/rooms/{code}` (spec §6.1, §8). No Cloud Functions — room
/// creation and the round-advance race are both client transactions.
class RoomRepository {
  RoomRepository({
    required DatabaseReference root,
    required String Function() currentUid,
    Random? random,
  })  : _root = root,
        _uid = currentUid,
        _random = random ?? Random.secure();

  final DatabaseReference _root;
  final String Function() _uid;
  final Random _random;

  DatabaseReference _room(String code) => _root.child("rooms/$code");

  Future<String> createRoom({int maxPlayers = 8, int maxAttempts = 8}) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = generateRoomCode(_random);
      final metaRef = _room(code).child("meta");
      final meta =
          RoomMeta(status: "lobby", hostUid: _uid(), maxPlayers: maxPlayers);
      final result = await metaRef.runTransaction((current) {
        if (current != null) return Transaction.abort();
        return Transaction.success(meta.toMap());
      });
      if (result.committed) return code;
    }
    throw const RoomCreateException("could not allocate a room code");
  }

  Future<void> joinRoom(String code, {required String displayName}) async {
    final metaSnap = await _room(code).child("meta").get();
    if (!metaSnap.exists) throw const RoomJoinException("room not found");
    final meta = RoomMeta.fromMap((metaSnap.value! as Map).cast());
    if (meta.status != "lobby") {
      throw const RoomJoinException("game already started");
    }
    final playersSnap = await _room(code).child("players").get();
    final currentCount =
        playersSnap.exists ? (playersSnap.value! as Map).length : 0;
    if (currentCount >= meta.maxPlayers) {
      throw const RoomJoinException("room is full");
    }

    final uid = _uid();
    final playerRef = _room(code).child("players/$uid");
    await playerRef.set({
      "name": displayName,
      "joinedAt": ServerValue.timestamp,
      "connected": true,
      "currentCardId": -1,
      "count": 0,
    });
    await playerRef.child("connected").onDisconnect().set(false);
  }

  Stream<RoomSnapshot> watchRoom(String code) => _room(code).onValue.map(
        (e) => RoomSnapshot.fromMap(code, (e.snapshot.value as Map?)?.cast()),
      );

  Future<void> setConnected(String code, {required bool connected}) =>
      _room(code).child("players/${_uid()}/connected").set(connected);

  Future<void> startGame(
    String code, {
    required List<int> deckOrder,
    required List<String> orderedUids,
  }) async {
    final updates = <String, Object?>{
      "rooms/$code/deck/order": deckOrder,
      "rooms/$code/deck/centerIndex": orderedUids.length,
      "rooms/$code/meta/status": "countdown",
    };
    for (var i = 0; i < orderedUids.length; i++) {
      updates["rooms/$code/players/${orderedUids[i]}/currentCardId"] =
          deckOrder[i];
    }
    await _root.update(updates);
  }

  Future<void> setPlaying(String code) =>
      _room(code).child("meta/status").set("playing");

  Future<bool> tryAdvance(
    String code, {
    required int expectedCenterIndex,
    required int newCenterCardId,
  }) async {
    final centerRef = _room(code).child("deck/centerIndex");
    final result = await centerRef.runTransaction((current) {
      final cur = (current as num?)?.toInt();
      // `current` starts as the client's local guess, which is `null`
      // before it has synced this path — only abort on a *confirmed*
      // mismatch. A null guess proposes the write anyway; if the real
      // server value differs, the SDK retries this callback with the
      // real value, and this check then correctly aborts.
      if (cur != null && cur != expectedCenterIndex) return Transaction.abort();
      return Transaction.success(expectedCenterIndex + 1);
    });
    if (!result.committed) return false;

    final uid = _uid();
    await _root.update({
      "rooms/$code/players/$uid/count": ServerValue.increment(1),
      "rooms/$code/players/$uid/currentCardId": newCenterCardId,
    });
    return true;
  }

  Future<void> writeResult(String code, RoomResult result) async {
    final resultRef = _room(code).child("result");
    final txn = await resultRef.runTransaction((current) {
      if (current != null) return Transaction.abort();
      return Transaction.success({
        "winnerUid": result.winnerUid,
        "standings": result.standings,
      });
    });
    if (txn.committed) {
      await _room(code).child("meta/status").set("finished");
    }
  }

  Future<void> electHost(String code, String newHostUid) =>
      _room(code).child("meta/hostUid").set(newHostUid);
}
