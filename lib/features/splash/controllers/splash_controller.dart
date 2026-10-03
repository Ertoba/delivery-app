import 'package:sixam_mart_delivery/api/api_response_extension.dart';
import 'package:sixam_mart_delivery/common/models/config_model.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/splash/domain/services/splash_service_interface.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/enums.dart';

class SplashController extends GetxController implements GetxService {
  final SplashServiceInterface splashServiceInterface;
  SplashController({required this.splashServiceInterface});

  ConfigModel? _configModel;
  ConfigModel? get configModel => _configModel;

  bool _firstTimeConnectionCheck = true;
  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;

  int? _storeCategoryID;
  int? get storeCategoryID => _storeCategoryID;

  String? _storeType;
  String? get storeType => _storeType;

  Map<String, dynamic>? _data = {};

  DateTime get currentTime => DateTime.now();

  Module getModuleConfig(String? moduleType) {
    Module module = Module.fromJson(_data!['module_config'][moduleType]);
    moduleType == 'food' ? module.newVariation = true : module.newVariation = false;
    return module;
  }

  Future<bool> getConfigData() async {
    Response response = await splashServiceInterface.getConfigData();
    splashServiceInterface.handleInitialTopicSubscription();
    bool isSuccess = false;
    if(response.statusCode == 200) {
      _data = response.content;
      _configModel = ConfigModel.fromJson(response.content);

      bool isMaintenanceMode = _configModel!.maintenanceMode ?? false;
      String platform = AppConstants.appMode == AppMode.delivery ? 'deliveryman_app' : "rider_app";
      bool isInMaintenance = isMaintenanceMode && (_configModel!.maintenanceModeData?.maintenanceSystemSetup?.contains(platform) ?? false);

      if(isMaintenanceMode) {
        print("maintenance mood on");
        Get.offNamed(RouteHelper.getUpdateRoute(false));
      }else if((Get.currentRoute.contains(RouteHelper.update) && !isMaintenanceMode) || (!isInMaintenance)) {
        if(Get.find<AuthController>().isLoggedIn()) {
          print("maintenance mood on - Off");
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else if(showLangIntro() && AppConstants.languages.length > 1) {
          Get.offNamed(RouteHelper.getLanguageRoute());
        } else {
          print("maintenance mood Off");
          Get.offNamed(RouteHelper.getSignInRoute());
        }
      }
      isSuccess = true;
    }else {
      isSuccess = false;
    }
    update();
    return isSuccess;
  }

  /// Re-fetches config without the maintenance/route handling of [getConfigData],
  /// so screens can pick up admin-side setting changes while the app is running.
  Future<bool> refreshConfigData() async {
    Response response = await splashServiceInterface.getConfigData();
    if(response.statusCode == 200) {
      _data = response.content;
      _configModel = ConfigModel.fromJson(response.content);
      update();
      return true;
    }
    return false;
  }

  Module getModule(String? moduleType) => Module.fromJson(_data!['module_config'][moduleType]);

  Future<bool> initSharedData() {
    return splashServiceInterface.initSharedData();
  }

  Future<bool> removeSharedData() {
    return splashServiceInterface.removeSharedData();
  }

  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }

  bool showLangIntro() {
    return splashServiceInterface.showLangIntro();
  }

  Future<bool> disableLangIntro() {
    return splashServiceInterface.disableLangIntro();
  }



  /// Rider module pusher config

  String? _pusherConnectionStatus;
  String? get pusherConnectionStatus => _pusherConnectionStatus;

  void setPusherStatus(String? connection){
    _pusherConnectionStatus = connection;
  }

}