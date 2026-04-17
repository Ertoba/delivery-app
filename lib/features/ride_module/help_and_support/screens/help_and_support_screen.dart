import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/features/chat/screens/conversation_screen.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'help_and_support'.tr),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            Icon(Icons.support_agent, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Text(
              'help_and_support'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Text(
              'for_any_assistance_contact_us'.tr.isNotEmpty ? 'for_any_assistance_contact_us'.tr : 'contact_us'.tr,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                ),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: Text('chat_with_us'.tr.isNotEmpty ? 'chat_with_us'.tr : 'live_chat'.tr,
                    style: robotoBold.copyWith(color: Colors.white)),
                onPressed: () => Get.to(() => const ConversationScreen()),
              ),
            ),

          ]),
        ),
      ),
    );
  }
}
