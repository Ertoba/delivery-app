// Legacy style identifiers now resolve exclusively to the bundled BPG faces.
import 'package:sixam_mart_delivery/util/typography.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';

const robotoRegular = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontFamilyFallback: MiliTypography.fallback,
  fontWeight: FontWeight.w400,
  fontSize: Dimensions.fontSizeDefault,
);

const robotoMedium = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontFamilyFallback: MiliTypography.fallback,
  fontWeight: FontWeight.w400,
  fontSize: Dimensions.fontSizeDefault,
);

const robotoSemiBold = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontFamilyFallback: MiliTypography.fallback,
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault,
);

const robotoBold = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontFamilyFallback: MiliTypography.fallback,
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault,
);

const robotoBlack = TextStyle(
  fontFamily: AppConstants.fontFamily,
  fontFamilyFallback: MiliTypography.fallback,
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault,
);

Color getStatusButtonColor(String? status) {
  return status == "completed"
      ? Theme.of(Get.context!).primaryColor
      : status == "cancelled"
      ? Theme.of(Get.context!).colorScheme.error
      : status == "ongoing"
      ? Colors.orange
      : status == "accepted"
      ? Colors.blue
      : Theme.of(Get.context!).hintColor;
}
