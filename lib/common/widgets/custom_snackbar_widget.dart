import 'package:fluttertoast/fluttertoast.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCustomSnackBar(
  String? message, {
  bool isError = true,
  bool getXSnackBar = true,
}) {
  final String displayMessage = _normalizeSnackBarMessage(message);
  if (getXSnackBar) {
    Get.showSnackbar(
      GetSnackBar(
        backgroundColor: isError ? Colors.red : Colors.green,
        message: displayMessage,
        duration: const Duration(seconds: 3),
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        borderRadius: 10,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  } else {
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

  final String? normalizedValidationMessage = _translateValidationMessage(
    rawMessage,
  );
  if (normalizedValidationMessage != null) {
    return normalizedValidationMessage;
  }

  return rawMessage;
}

String? _translateValidationMessage(String message) {
  final RegExpMatch? requiredFieldMatch = RegExp(
    r'^The (.+) field is required\.$',
    caseSensitive: false,
  ).firstMatch(message);
  if (requiredFieldMatch != null) {
    final String fieldName = _translateValidationField(
      requiredFieldMatch.group(1),
    );
    return '$fieldName აუცილებელია.';
  }

  final RegExpMatch? alreadyTakenMatch = RegExp(
    r'^The (.+) has already been taken\.?$',
    caseSensitive: false,
  ).firstMatch(message);
  if (alreadyTakenMatch != null) {
    final String fieldName = _translateValidationField(
      alreadyTakenMatch.group(1),
    );
    return '$fieldName უკვე გამოყენებულია.';
  }

  final RegExpMatch? invalidSelectedMatch = RegExp(
    r'^The selected (.+) is invalid\.?$',
    caseSensitive: false,
  ).firstMatch(message);
  if (invalidSelectedMatch != null) {
    final String fieldName = _translateValidationField(
      invalidSelectedMatch.group(1),
    );
    return 'არჩეული $fieldName არასწორია.';
  }

  final RegExpMatch? validEmailMatch = RegExp(
    r'^The (.+) must be a valid email address\.?$',
    caseSensitive: false,
  ).firstMatch(message);
  if (validEmailMatch != null) {
    final String fieldName = _translateValidationField(
      validEmailMatch.group(1),
    );
    return '$fieldName არასწორია.';
  }

  final RegExpMatch? minLengthMatch = RegExp(
    r'^The (.+) must be at least (\d+) characters(?: long)?\.?$',
    caseSensitive: false,
  ).firstMatch(message);
  if (minLengthMatch != null) {
    final String fieldName = _translateValidationField(minLengthMatch.group(1));
    final String minLength = minLengthMatch.group(2) ?? '';
    return '$fieldName მინიმუმ $minLength სიმბოლო უნდა იყოს.';
  }

  return null;
}

String _translateValidationField(String? field) {
  final String normalizedField = (field ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');

  const Map<String, String> fieldTranslations = {
    'phone': 'ტელეფონის ნომერი',
    'phone number': 'ტელეფონის ნომერი',
    'email': 'ელფოსტა',
    'password': 'პაროლი',
    'confirm password': 'პაროლის დადასტურება',
    'name': 'სახელი',
    'f name': 'სახელი',
    'l name': 'გვარი',
    'address': 'მისამართი',
    'code': 'კოდი',
    'token': 'კოდი',
    'otp': 'კოდი',
    'module type': 'მოდულის ტიპი',
    'module name': 'მოდულის სახელი',
    'payment method': 'გადახდის მეთოდი',
    'login type': 'შესვლის ტიპი',
    'trip status': 'სტატუსი',
  };

  return fieldTranslations[normalizedField] ?? normalizedField;
}
