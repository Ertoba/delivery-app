import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart_delivery/common/models/response_model.dart';
import 'package:sixam_mart_delivery/features/address/domain/models/record_location_body_model.dart';
import 'package:sixam_mart_delivery/features/home/widgets/location_access_dialog.dart';
import 'package:sixam_mart_delivery/features/profile/domain/models/profile_model.dart';
import 'package:sixam_mart_delivery/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:sixam_mart_delivery/features/profile/domain/services/location_permission_coordinator.dart';
import 'package:geocoding/geocoding.dart' as geo_coding;
import 'package:sixam_mart_delivery/features/profile/domain/services/profile_service_interface.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

class ProfileService implements ProfileServiceInterface {
  final ProfileRepositoryInterface profileRepositoryInterface;
  final SharedPreferences sharedPreferences;
  late final LocationPermissionCoordinator _locationPermissionCoordinator;

  ProfileService({required this.profileRepositoryInterface, required this.sharedPreferences, LocationPermissionCoordinator? locationPermissionCoordinator}) {
    _locationPermissionCoordinator = locationPermissionCoordinator ?? LocationPermissionCoordinator(
      isAndroid: GetPlatform.isAndroid,
      readConsent: () => sharedPreferences.getBool(AppConstants.locationDisclosureConsent) ?? false,
      saveConsent: () async {
        await sharedPreferences.setBool(AppConstants.locationDisclosureConsent, true);
      },
      checkPermission: Geolocator.checkPermission,
      requestPermission: Geolocator.requestPermission,
      openAppSettings: Geolocator.openAppSettings,
      presentDisclosure: _presentLocationDisclosure,
    );
  }

  static Future<bool> _presentLocationDisclosure(LocationDisclosureStep step) async {
    if (Get.isDialogOpen == true) {
      return false;
    }
    return await Get.dialog<bool>(LocationAccessDialog(step: step), barrierDismissible: false) ?? false;
  }

  @override
  Future<ProfileModel?> getProfileInfo() async {
    return await profileRepositoryInterface.getProfileInfo();
  }

  @override
  Future<ResponseModel> updateProfile(
    ProfileModel userInfoModel,
    XFile? data,
    String token,
  ) async {
    return await profileRepositoryInterface.updateProfile(
      userInfoModel,
      data,
      token,
    );
  }

  @override
  Future<ResponseModel> updateActiveStatus() async {
    return await profileRepositoryInterface.updateActiveStatus();
  }

  @override
  Future<void> recordWebSocketLocation(
    RecordLocationBodyModel recordLocationBody,
    String zoneId,
  ) async {
    await profileRepositoryInterface.recordWebSocketLocation(
      recordLocationBody,
      zoneId,
    );
  }

  @override
  Future<Response> recordLocation(
    RecordLocationBodyModel recordLocationBody,
    String zoneId,
  ) async {
    return await profileRepositoryInterface.recordLocation(
      recordLocationBody,
      zoneId,
    );
  }

  @override
  Future<String> getZoneId(Position locationResult) async {
    return await profileRepositoryInterface.getZoneId(locationResult);
  }

  @override
  Future<ResponseModel> deleteDriver() async {
    return await profileRepositoryInterface.deleteDriver();
  }

  @override
  Future<String> addressPlaceMark(Position locationResult) async {
    String address;
    try {
      await geo_coding.setLocaleIdentifier('ka_GE');
      List<geo_coding.Placemark> addresses = await geo_coding
          .placemarkFromCoordinates(
            locationResult.latitude,
            locationResult.longitude,
          );
      geo_coding.Placemark placeMark = addresses.first;
      List<String?> parts = [
        placeMark.street,
        placeMark.subLocality,
        placeMark.locality?.isNotEmpty == true
            ? placeMark.locality
            : placeMark.subAdministrativeArea,
        placeMark.country,
      ];
      address = parts
          .where((part) => part != null && part.trim().isNotEmpty)
          .map((part) => part!.trim())
          .toSet()
          .join(', ')
          .replaceAll(RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,3}[,\s]*'), '')
          .trim();
      if (address.isEmpty) {
        address = 'მდებარეობა ვერ მოიძებნა';
      }
    } catch (e) {
      address = 'მდებარეობა ვერ მოიძებნა';
    }
    return address;
  }

  @override
  void checkPermission(Function callback) async {
    if (await _locationPermissionCoordinator.ensurePermission()) {
      callback();
    }
  }

  @override
  Future<bool> hasLocationConsentAndPermission() {
    return _locationPermissionCoordinator.isReady();
  }

  @override
  Future getProfileLevelInfo() {
    return profileRepositoryInterface.getProfileLevelInfo();
  }
}
