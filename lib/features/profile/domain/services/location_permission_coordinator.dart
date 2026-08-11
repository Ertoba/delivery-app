import 'package:geolocator/geolocator.dart';

enum LocationDisclosureStep {
  foregroundPermission,
  backgroundSettings,
  appSettings,
}

typedef LocationDisclosurePresenter =
    Future<bool> Function(LocationDisclosureStep step);

class LocationPermissionCoordinator {
  final bool isAndroid;
  final bool Function() readConsent;
  final Future<void> Function() saveConsent;
  final Future<LocationPermission> Function() checkPermission;
  final Future<LocationPermission> Function() requestPermission;
  final Future<bool> Function() openAppSettings;
  final LocationDisclosurePresenter presentDisclosure;

  bool _flowInProgress = false;

  LocationPermissionCoordinator({
    required this.isAndroid,
    required this.readConsent,
    required this.saveConsent,
    required this.checkPermission,
    required this.requestPermission,
    required this.openAppSettings,
    required this.presentDisclosure,
  });

  Future<bool> ensurePermission() async {
    if (_flowInProgress) {
      return false;
    }

    _flowInProgress = true;
    try {
      LocationPermission permission = await checkPermission();

      if (_hasRequiredPermission(permission) && readConsent()) {
        return true;
      }

      final LocationDisclosureStep initialStep = _disclosureStep(permission);
      if (!await presentDisclosure(initialStep)) {
        return false;
      }
      await saveConsent();

      if (_hasRequiredPermission(permission)) {
        return true;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await requestPermission();

        if (_hasRequiredPermission(permission)) {
          return true;
        }

        if (isAndroid && permission == LocationPermission.whileInUse) {
          if (await presentDisclosure(
            LocationDisclosureStep.backgroundSettings,
          )) {
            await saveConsent();
            await openAppSettings();
          }
        }
        return false;
      }

      await openAppSettings();
      return false;
    } finally {
      _flowInProgress = false;
    }
  }

  Future<bool> isReady() async {
    if (!readConsent()) {
      return false;
    }
    return _hasRequiredPermission(await checkPermission());
  }

  bool _hasRequiredPermission(LocationPermission permission) {
    if (isAndroid) {
      return permission == LocationPermission.always;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  LocationDisclosureStep _disclosureStep(LocationPermission permission) {
    if (isAndroid && permission == LocationPermission.whileInUse) {
      return LocationDisclosureStep.backgroundSettings;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationDisclosureStep.appSettings;
    }
    return LocationDisclosureStep.foregroundPermission;
  }
}
