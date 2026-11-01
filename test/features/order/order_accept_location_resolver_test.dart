import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/repositories/order_accept_location_resolver.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 7);
  Position position({int age = 0, double accuracy = 10, double latitude = 41.5}) =>
      Position(latitude: latitude, longitude: 44.5,
        timestamp: now.subtract(Duration(seconds: age)), accuracy: accuracy,
        altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0,
        speed: 0, speedAccuracy: 0);

  test('fresh accurate tracked location avoids another GPS wait', () async {
    int gpsCalls = 0;
    final cached = position(age: 3);
    final resolver = OrderAcceptLocationResolver(
      lastKnownPosition: () async => cached,
      currentPosition: () async { gpsCalls++; return position(); },
      now: () => now,
    );
    expect(await resolver.resolve(), same(cached));
    expect(gpsCalls, 0);
  });

  for (final cached in [position(age: 60), position(accuracy: 80),
    position(age: -30), position(latitude: double.nan)]) {
    test('stale/inaccurate/future/invalid cache requires fresh GPS: $cached', () async {
      final fresh = position();
      int gpsCalls = 0;
      final resolver = OrderAcceptLocationResolver(
        lastKnownPosition: () async => cached,
        currentPosition: () async { gpsCalls++; return fresh; },
        now: () => now,
      );
      expect(await resolver.resolve(), same(fresh));
      expect(gpsCalls, 1);
    });
  }

  test('unavailable GPS with no valid cache fails without fabricated coordinates', () async {
    final resolver = OrderAcceptLocationResolver(
      lastKnownPosition: () async => null,
      currentPosition: () async => throw StateError('GPS unavailable'),
      now: () => now,
    );
    expect(await resolver.resolve(), isNull);
  });
}
