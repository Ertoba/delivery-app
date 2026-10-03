import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class PassViewWidget extends StatelessWidget {
  const PassViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        return Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: Wrap(children: [

            _View(title: '8_or_more_character'.tr, done: authController.lengthCheck),

            _View(title: '1_number'.tr, done: authController.numberCheck),

            _View(title: '1_upper_case'.tr, done: authController.uppercaseCheck),

            _View(title: '1_lower_case'.tr, done: authController.lowercaseCheck),

            _View(title: '1_special_character'.tr, done: authController.spatialCheck),

          ]),
        );
      }
    );
  }

}

class _View extends StatelessWidget {
  final String title;
  final bool done;
  const _View({required this.title, required this.done});

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(done ? Icons.check : Icons.clear, color: done ? Colors.green : Colors.red, size: 12),
        Text(title, style: robotoRegular.copyWith(color: done ? Colors.green : Colors.red, fontSize: 12))
      ]),
    );
  }
}
