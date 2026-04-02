import 'package:fluttertoast/fluttertoast.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCustomSnackBar(String? message, {bool isError = true, bool getXSnackBar = true}) {
  final String displayMessage = _normalizeSnackBarMessage(message);
  if (getXSnackBar) {
    Get.showSnackbar(GetSnackBar(
      backgroundColor: isError ? Colors.red : Colors.green,
      message: displayMessage,
      duration: const Duration(seconds: 3),
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      borderRadius: 10,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    ));
  }else{
    Fluttertoast.showToast(
      msg: displayMessage,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

String _normalizeSnackBarMessage(String? message) {
  final String fallbackMessage = 'request_failed'.tr;
  final String rawMessage = (message?.trim().isNotEmpty ?? false)
      ? message!.trim()
      : fallbackMessage;

  if (Get.locale?.languageCode != 'ka') {
    return rawMessage;
  }

  final Map<String, String> exactMatches = {
    'Phone number not found!': 'phone_number_not_found'.tr,
    'Email not found!': 'email_not_found'.tr,
    'Failed to send email.': 'failed_to_send_email'.tr,
    'Failed to send SMS.': 'failed_to_send_sms_popup'.tr,
    'Otp Successfully Sent To Your Phone':
        'otp_successfully_sent_to_your_phone'.tr,
    'Otp Successfully Sent To Your Mail':
        'otp_successfully_sent_to_your_mail'.tr,
    'Otp Successfully Sent To Your Phone and Mail':
        'otp_successfully_sent_to_your_phone_and_mail'.tr,
    'OTP found, you can proceed': 'otp_found_you_can_proceed'.tr,
    'Token found, you can proceed': 'otp_found_you_can_proceed'.tr,
    'Invalid token.': 'invalid_token_popup'.tr,
    'Connection to API server failed due to internet connection':
        'connection_to_api_server_failed'.tr,
    'Request failed': fallbackMessage,
  };

  if (exactMatches.containsKey(rawMessage)) {
    return exactMatches[rawMessage]!;
  }

  final RegExp requestFailedPattern = RegExp(r'^Request failed \(\d+\)$');
  if (requestFailedPattern.hasMatch(rawMessage)) {
    return fallbackMessage;
  }

  return rawMessage;
}
