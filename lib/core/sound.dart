import "package:flutter/services.dart";

/// Lightweight sound cues using the platform's built-in system sounds — no
/// audio assets or plugins. Richer sfx can replace these later behind the
/// same call sites.
void sfxMatch({required bool enabled}) {
  if (enabled) SystemSound.play(SystemSoundType.click);
}

void sfxWrong({required bool enabled}) {
  if (enabled) SystemSound.play(SystemSoundType.alert);
}

void sfxTick({required bool enabled}) {
  if (enabled) SystemSound.play(SystemSoundType.click);
}
