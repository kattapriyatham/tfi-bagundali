import "package:flutter/services.dart";

/// Small wrappers so screens can fire feedback in one line, gated by the
/// user's haptics setting.
void hapticMatch({required bool enabled}) {
  if (enabled) HapticFeedback.selectionClick();
}

void hapticWrong({required bool enabled}) {
  if (enabled) HapticFeedback.heavyImpact();
}
