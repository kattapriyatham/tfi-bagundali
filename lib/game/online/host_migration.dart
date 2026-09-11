import "../../rooms/room_models.dart";

/// The connected player with the earliest `joinedAt`, or null if nobody is
/// connected (spec §8.3: deterministic host migration).
String? electedHost(RoomSnapshot snapshot) {
  final connected = snapshot.players.entries.where((e) => e.value.connected);
  if (connected.isEmpty) return null;
  return connected
      .reduce((a, b) => a.value.joinedAt <= b.value.joinedAt ? a : b)
      .key;
}

/// True iff the room's current host has disconnected and [myUid] is the
/// one who should take over.
bool shouldIElectMyself(RoomSnapshot snapshot, String myUid) {
  final currentHost = snapshot.players[snapshot.meta.hostUid];
  final hostIsConnected = currentHost?.connected ?? false;
  if (hostIsConnected) return false;
  return electedHost(snapshot) == myUid;
}
