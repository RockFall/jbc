/// Hash estável entre dispositivos (mesmo algoritmo, mesma string).
int timelineCollageSeed(String eventId) {
  var h = 5381;
  for (final u in eventId.codeUnits) {
    h = (h * 33 + u) & 0x7fffffff;
  }
  return h == 0 ? 1 : h;
}

double collageAngleRad(int seed, int index, {required bool reduceMotion}) {
  if (reduceMotion) return 0;
  final x = (seed + index * 104729) & 0xffff;
  return (x / 0xffff - 0.5) * 0.14;
}

double collageOffsetX(int seed, int index) {
  final x = (seed * (index + 3) + index * 7919) & 0xff;
  return (x / 0xff - 0.5) * 18;
}

double collageOffsetY(int seed, int index) {
  final y = (seed * (index + 7) + index * 503) & 0xff;
  return (y / 0xff - 0.5) * 14;
}
