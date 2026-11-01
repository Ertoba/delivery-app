import 'package:geolocator/geolocator.dart';

/// Uses the already-running location tracker before waiting for another GPS fix.
class OrderAcceptLocationResolver {
  final Future<Position?> Function() lastKnownPosition;
  final Future<Position> Function() currentPosition;
  final DateTime Function() now;

  OrderAcceptLocationResolver({
    Future<Position?> Function()? lastKnownPosition,
    Future<Position> Function()? currentPosition,
    DateTime Function()? now,
  }) : lastKnownPosition = lastKnownPosition ?? Geolocator.getLastKnownPosition,
       currentPosition = currentPosition ?? _getCurrentPosition,
       now = now ?? DateTime.now;

  static Future<Position> _getCurrentPosition() =>
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

  Future<Position?> resolve() async {
    final Position? cached = await _recentLastKnownPosition();
    if (cached != null) return cached;
    try {
      final Position position = await currentPosition();
      return _hasValidCoordinates(position) ? position : null;
    } catch (_) {
      return _recentLastKnownPosition();
    }
  }

  Future<Position?> _recentLastKnownPosition() async {
    try {
      final Position? position = await lastKnownPosition().timeout(
        const Duration(seconds: 1),
      );
      if (position == null || !_hasValidCoordinates(position)) return null;
      final Duration age = now().difference(position.timestamp);
      // A ten-minute / unbounded-accuracy fix can misrepresent the pickup area.
      return age >= Duration.zero &&
              age <= const Duration(seconds: 15) &&
              position.accuracy.isFinite &&
              position.accuracy > 0 &&
              position.accuracy <= 100
          ? position
          : null;
    } catch (_) {
      return null;
    }
  }

  bool _hasValidCoordinates(Position position) =>
      position.latitude.isFinite &&
      position.longitude.isFinite &&
      position.latitude >= -90 &&
      position.latitude <= 90 &&
      position.longitude >= -180 &&
      position.longitude <= 180;
}
