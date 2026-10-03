import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';

class DistanceConverterHelper {
  static const String _km = 'km';
  static const String _mile = 'mi';
  static const double _kmToMile = 0.621371;

  /// Distance unit configured from admin panel (`km` or `mi`). Falls back to `km`.
  static String get unit {
    String unit = Get.find<SplashController>().configModel?.distanceUnit?.trim().toLowerCase() ?? '';
    return (unit == _mile || unit == 'mile' || unit == 'miles') ? _mile : _km;
  }

  static bool get isMile => unit == _mile;

  /// Translated unit text, ex: `km` / `mi`
  static String get unitText => isMile ? _mile.tr : _km.tr;

  /// Converts a distance measured in kilometer to the configured unit.
  static double convertDistance(double distanceInKm) => isMile ? distanceInKm * _kmToMile : distanceInKm;

  /// Single source of truth for conversion, capping and rounding.
  /// [maxDistance] is expressed in the configured unit.
  static String _format(double? distanceInKm, String suffix, {int asFixed = 2, int maxDistance = 1000}) {
    double distance = convertDistance(distanceInKm ?? 0);
    return '${distance > maxDistance ? '$maxDistance+' : distance.toStringAsFixed(asFixed)} $suffix';
  }

  /// Converted distance with unit, ex: `2.50 km` / `1.55 mi`
  static String getDistanceWithUnit(double? distanceInKm, {int asFixed = 2, int maxDistance = 1000}) {
    return _format(distanceInKm, unitText, asFixed: asFixed, maxDistance: maxDistance);
  }

  /// Converted distance with unit, ex: `2.50 km away from you` / `1.55 mi away from you`
  static String getDistanceAwayFromYou(double? distanceInKm, {int asFixed = 2, int maxDistance = 1000}) {
    return _format(distanceInKm, isMile ? 'mi_away_from_you'.tr : 'km_away_from_you'.tr, asFixed: asFixed, maxDistance: maxDistance);
  }

  /// Converted distance with unit, ex: `2.50 Km Aprox` / `1.55 Mi Aprox`
  static String getDistanceAprox(double? distanceInKm, {int asFixed = 2, int maxDistance = 1000}) {
    return _format(distanceInKm, isMile ? 'mi_aprox'.tr : 'km_aprox'.tr, asFixed: asFixed, maxDistance: maxDistance);
  }
}
