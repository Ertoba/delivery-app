import 'dart:async';
import 'package:sixam_mart_delivery/common/models/response_model.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/profile/domain/models/level_model.dart';
import 'package:sixam_mart_delivery/features/ride_module/map/controllers/ride_map_controller.dart';
import 'package:sixam_mart_delivery/features/ride_module/ride_order/controllers/ride_controller.dart';
import 'package:sixam_mart_delivery/features/address/domain/models/record_location_body_model.dart';
import 'package:sixam_mart_delivery/features/profile/domain/models/profile_model.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart_delivery/helper/pusher_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart_delivery/features/profile/domain/services/profile_service_interface.dart';

class ProfileController extends GetxController implements GetxService {
  final ProfileServiceInterface profileServiceInterface;
  ProfileController({required this.profileServiceInterface});

  ProfileModel? _profileModel;
  ProfileModel? get profileModel => _profileModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  XFile? _pickedFile;
  XFile? get pickedFile => _pickedFile;

  RecordLocationBodyModel? _recordLocation;
  RecordLocationBodyModel? get recordLocationBody => _recordLocation;

  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  Position? _latestPosition;
  Position? _lastRecordedPosition;
  bool _isRecordingLocation = false;
  String _lastLocationSource = 'unknown';

  static const Duration _maxCachedPositionAge = Duration(seconds: 15);
  static const Duration _locationRecordInterval = Duration(seconds: 5);
  static const double _meaningfulLocationDistance = 2;
  static final LocationSettings _locationSettings =
      defaultTargetPlatform == TargetPlatform.android
      ? AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
          intervalDuration: _locationRecordInterval,
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: 'Portal Delivery',
            notificationText: 'Location tracking is active for deliveries.',
            enableWakeLock: true,
            setOngoing: true,
          ),
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        );

  bool _backgroundNotification = true;
  bool get backgroundNotification => _backgroundNotification;

  LevelModel? _levelModel;
  LevelModel? get levelModel => _levelModel;

  Future<void> getProfileLevelInfo() async {
    Response response = await profileServiceInterface.getProfileLevelInfo();
    if (response.statusCode == 200) {
      _levelModel = LevelModel.fromJson(response.body);
    } /*else{
      ApiChecker.checkApi(response);
    }*/
    update();
  }

  Future<ProfileModel?> getProfile() async {
    ProfileModel? profileModel = await profileServiceInterface.getProfileInfo();
    if (profileModel != null) {
      _profileModel = profileModel;

      PusherHelper().driverTripRequestSubscribe(_profileModel!.id.toString());

      if (_profileModel!.active == 1) {
        profileServiceInterface.checkPermission(() => startLocationRecord());
      } else {
        stopLocationRecord();
      }
    }
    update();
    return profileModel;
  }

  Future<bool> updateUserInfo(
    ProfileModel updateUserModel,
    String token,
  ) async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await profileServiceInterface.updateProfile(
      updateUserModel,
      _pickedFile,
      token,
    );
    _isLoading = false;
    if (responseModel.isSuccess) {
      _profileModel = updateUserModel;
      Get.back();
      showCustomSnackBar(responseModel.message, isError: false);
    } else {
      showCustomSnackBar(responseModel.message, isError: true);
    }
    update();
    return responseModel.isSuccess;
  }

  void pickImage() async {
    _pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    update();
  }

  void initData() {
    _pickedFile = null;
  }

  Future<bool> updateActiveStatus() async {
    ResponseModel responseModel = await profileServiceInterface
        .updateActiveStatus();
    if (responseModel.isSuccess) {
      Get.back();
      _profileModel!.active = _profileModel!.active == 0 ? 1 : 0;
      showCustomSnackBar(responseModel.message, isError: false);
      if (_profileModel!.active == 1) {
        profileServiceInterface.checkPermission(() => startLocationRecord());
      } else {
        stopLocationRecord();
      }
    } else {
      showCustomSnackBar(responseModel.message, isError: true);
    }
    update();
    return responseModel.isSuccess;
  }

  Future deleteDriver() async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await profileServiceInterface.deleteDriver();
    _isLoading = false;
    if (responseModel.isSuccess) {
      showCustomSnackBar(responseModel.message, isError: false);
      Get.find<AuthController>().clearSharedData();
      stopLocationRecord();
      PusherHelper().pusherDisconnectPusher();
      Get.offAllNamed(RouteHelper.getSignInRoute());
    } else {
      Get.back();
      showCustomSnackBar(responseModel.message, isError: true);
    }
  }

  void startLocationRecord() {
    if (_positionSubscription == null) {
      _startPositionStream();
    }
    if (_timer?.isActive ?? false) {
      return;
    }

    recordLocation();
    _timer = Timer.periodic(_locationRecordInterval, (timer) {
      recordLocation();
    });
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings,
        ).listen(
          (Position position) {
            _latestPosition = position;
            _logPosition('stream', position);
          },
          onError: (Object error) {
            debugPrint('[LOCATION] stream error=$error');
            _positionSubscription = null;
          },
          onDone: () => _positionSubscription = null,
        );
  }

  void stopLocationRecord() {
    _timer?.cancel();
    _timer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _latestPosition = null;
    _lastRecordedPosition = null;
    _lastLocationSource = 'unknown';
  }

  Future<void> recordLocation() async {
    if (_isRecordingLocation) {
      return;
    }

    _isRecordingLocation = true;
    try {
      final Position locationResult = await _getLocationForRecording();
      _logPosition(
        'record source=$_lastLocationSource',
        locationResult,
        previousPosition: _lastRecordedPosition,
      );

      String address = await profileServiceInterface.addressPlaceMark(
        locationResult,
      );
      String zoneId = await profileServiceInterface.getZoneId(locationResult);

      _recordLocation = RecordLocationBodyModel(
        location: address,
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
        zoneId: zoneId,
      );

      List<String> status = ['accepted', 'ongoing'];
      if (Get.find<RideController>().tripDetail != null &&
          status.contains(
            Get.find<RiderMapController>().currentRideState.name,
          ) &&
          Get.find<AuthController>().getUserToken() != '') {
        Get.find<RideController>().remainingDistance(
          Get.find<RideController>().tripDetail!.id!,
        );
      }

      if (Get.find<AuthController>().isLoggedIn()) {
        await profileServiceInterface.recordLocation(_recordLocation!, zoneId);
        _lastRecordedPosition = locationResult;
      }
    } finally {
      _isRecordingLocation = false;
    }
  }

  Future<Position> _getLocationForRecording() async {
    final Position? latestPosition = _latestPosition;
    if (_positionSubscription == null) {
      _startPositionStream();
    }

    try {
      final Position locationResult = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      _logPosition('current', locationResult, previousPosition: latestPosition);
      final Position selectedPosition = _selectLocationForRecording(
        currentPosition: locationResult,
        streamPosition: latestPosition,
      );
      _latestPosition = selectedPosition;
      return selectedPosition;
    } catch (_) {
      if (latestPosition != null && _isFreshPosition(latestPosition)) {
        _lastLocationSource = 'stream_fallback';
        return latestPosition;
      }
      rethrow;
    }
  }

  bool _isFreshPosition(Position position) {
    final int ageInSeconds = DateTime.now()
        .difference(position.timestamp)
        .inSeconds
        .abs();
    return ageInSeconds <= _maxCachedPositionAge.inSeconds;
  }

  Position _selectLocationForRecording({
    required Position currentPosition,
    required Position? streamPosition,
  }) {
    _lastLocationSource = 'current';

    if (streamPosition == null || !_isFreshPosition(streamPosition)) {
      return currentPosition;
    }

    final int streamAgeMs = _positionAgeInMilliseconds(streamPosition);
    final int currentAgeMs = _positionAgeInMilliseconds(currentPosition);
    final double? streamDistance = _distanceFromLastRecordedPosition(
      streamPosition,
    );
    final double? currentDistance = _distanceFromLastRecordedPosition(
      currentPosition,
    );
    final bool streamIsNewer =
        streamPosition.timestamp.isAfter(currentPosition.timestamp) ||
        currentAgeMs - streamAgeMs > Duration.millisecondsPerSecond;
    final bool streamMovedFurther =
        streamDistance != null &&
        currentDistance != null &&
        streamDistance - currentDistance >= _meaningfulLocationDistance;

    if (streamIsNewer || streamMovedFurther) {
      _lastLocationSource = streamIsNewer ? 'stream_newer' : 'stream_moved';
      _logPosition(
        'selected $_lastLocationSource',
        streamPosition,
        previousPosition: _lastRecordedPosition,
      );
      return streamPosition;
    }

    return currentPosition;
  }

  double? _distanceFromLastRecordedPosition(Position position) {
    final Position? lastPosition = _lastRecordedPosition;
    if (lastPosition == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      lastPosition.latitude,
      lastPosition.longitude,
      position.latitude,
      position.longitude,
    );
  }

  int _positionAgeInMilliseconds(Position position) {
    return DateTime.now().difference(position.timestamp).inMilliseconds.abs();
  }

  void _logPosition(
    String label,
    Position position, {
    Position? previousPosition,
  }) {
    final double? distance = previousPosition == null
        ? null
        : Geolocator.distanceBetween(
            previousPosition.latitude,
            previousPosition.longitude,
            position.latitude,
            position.longitude,
          );
    final String distanceText = distance == null
        ? '-'
        : distance.toStringAsFixed(1);

    debugPrint(
      '[LOCATION] $label '
      'lat=${position.latitude.toStringAsFixed(7)} '
      'lng=${position.longitude.toStringAsFixed(7)} '
      'acc=${position.accuracy.toStringAsFixed(1)}m '
      'speed=${position.speed.toStringAsFixed(2)}mps '
      'age=${_positionAgeInMilliseconds(position)}ms '
      'delta=${distanceText}m',
    );
  }

  void setBackgroundNotificationActive(bool isActive) {
    _backgroundNotification = isActive;
    update();
  }
}
