import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sixam_mart_delivery/features/profile/domain/services/location_permission_coordinator.dart';

void main() {
  group('LocationPermissionCoordinator', () {
    test('shows disclosure immediately before the runtime request', () async {
      final events = <String>[];
      var consent = false;

      final coordinator = _coordinator(
        events: events,
        initialPermission: LocationPermission.denied,
        requestedPermission: LocationPermission.always,
        readConsent: () => consent,
        saveConsent: () async {
          events.add('save-consent');
          consent = true;
        },
      );

      expect(await coordinator.ensurePermission(), isTrue);
      expect(events, [
        'check',
        'disclosure:foregroundPermission',
        'save-consent',
        'request',
      ]);
    });

    test('does not request permission when disclosure is declined', () async {
      final events = <String>[];

      final coordinator = _coordinator(
        events: events,
        initialPermission: LocationPermission.denied,
        requestedPermission: LocationPermission.always,
        disclosureAccepted: false,
      );

      expect(await coordinator.ensurePermission(), isFalse);
      expect(events, ['check', 'disclosure:foregroundPermission']);
    });

    test('explains background access before opening settings', () async {
      final events = <String>[];

      final coordinator = _coordinator(
        events: events,
        initialPermission: LocationPermission.denied,
        requestedPermission: LocationPermission.whileInUse,
      );

      expect(await coordinator.ensurePermission(), isFalse);
      expect(events, [
        'check',
        'disclosure:foregroundPermission',
        'save-consent',
        'request',
        'disclosure:backgroundSettings',
        'save-consent',
        'settings',
      ]);
    });

    test(
      'requires disclosure for an existing permission without consent',
      () async {
        final events = <String>[];

        final coordinator = _coordinator(
          events: events,
          initialPermission: LocationPermission.always,
          requestedPermission: LocationPermission.always,
        );

        expect(await coordinator.ensurePermission(), isTrue);
        expect(events, [
          'check',
          'disclosure:foregroundPermission',
          'save-consent',
        ]);
      },
    );

    test('starts silently only after consent and full permission', () async {
      final events = <String>[];

      final coordinator = _coordinator(
        events: events,
        initialPermission: LocationPermission.always,
        requestedPermission: LocationPermission.always,
        readConsent: () => true,
      );

      expect(await coordinator.ensurePermission(), isTrue);
      expect(events, ['check']);
    });
  });
}

LocationPermissionCoordinator _coordinator({
  required List<String> events,
  required LocationPermission initialPermission,
  required LocationPermission requestedPermission,
  bool disclosureAccepted = true,
  bool Function()? readConsent,
  Future<void> Function()? saveConsent,
}) {
  return LocationPermissionCoordinator(
    isAndroid: true,
    readConsent: readConsent ?? () => false,
    saveConsent:
        saveConsent ??
        () async {
          events.add('save-consent');
        },
    checkPermission: () async {
      events.add('check');
      return initialPermission;
    },
    requestPermission: () async {
      events.add('request');
      return requestedPermission;
    },
    openAppSettings: () async {
      events.add('settings');
      return true;
    },
    presentDisclosure: (step) async {
      events.add('disclosure:${step.name}');
      return disclosureAccepted;
    },
  );
}
