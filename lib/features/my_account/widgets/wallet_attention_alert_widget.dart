import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class WalletAttentionAlertWidget extends StatelessWidget {
  final bool isOverFlowBlockWarning;
  const WalletAttentionAlertWidget({super.key, required this.isOverFlowBlockWarning});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Container(
          width: context.width * 0.95,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: const Color(0xfffff1f1),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(children: [

              Image.asset(Images.attentionWarningIcon, width: 20, height: 20),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Text('attention_please'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black)),

            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            isOverFlowBlockWarning ? RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                text: '${'over_flow_block_warning_message'.tr}  ',
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black),
                children: [
                  TextSpan(
                    recognizer: TapGestureRecognizer()..onTap = () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text('cash_handover'.tr, textAlign: TextAlign.center),
                          content: Text('cash_handover_instruction'.tr, textAlign: TextAlign.center),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: Text('ok'.tr),
                            ),
                          ],
                        ),
                      );
                    },
                    text: 'hand_over_cash'.tr,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ) : Text('over_flow_warning_message'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black)),
          ]),
        );
      }
    );
  }
}
