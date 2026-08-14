import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/api_error_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart_delivery/common/models/error_response.dart';

class ApiChecker {
  static void checkApi(Response response) {
    if(response.statusCode == 401) {
      Get.find<AuthController>().clearSharedData();
      Get.find<ProfileController>().stopLocationRecord();
      if(Get.currentRoute != RouteHelper.signIn){
        Get.offAllNamed(RouteHelper.getSignInRoute());
      }
      return;
    }

    ErrorResponse? errorResponse;
    final Map<String, dynamic>? responseBody =
        response.body is Map<String, dynamic>
            ? response.body as Map<String, dynamic>
            : null;

    if(responseBody != null) {
      try {
        errorResponse = ErrorResponse.fromJson(responseBody);
      } catch(e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }

    String? message = response.statusText;
    if(responseBody?['message'] != null) {
      message = responseBody!['message'].toString();
    } else if(errorResponse?.errors != null && errorResponse!.errors!.isNotEmpty) {
      message = errorResponse.errors!.first.message;
    }

    showCustomSnackBar(
      ApiErrorHelper.userMessage(
        message,
        statusCode: response.statusCode,
      ),
    );
  }
}
