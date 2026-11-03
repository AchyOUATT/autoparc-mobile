/// A missing or invalid reading stays unknown; only an explicit zero is 0 km.
int? parseMileageKm(Object? value) {
  final num? reading = switch (value) {
    num n => n,
    String text => num.tryParse(text.trim()),
    _ => null,
  };
  if (reading == null ||
      !reading.isFinite ||
      reading < 0 ||
      reading != reading.truncateToDouble()) {
    return null;
  }
  return reading.toInt();
}
