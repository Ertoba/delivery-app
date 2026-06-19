import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/my_account/controllers/my_account_controller.dart';
import 'package:sixam_mart_delivery/features/my_account/helpers/payment_method_filter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_image_widget.dart';

class PaymentMethodBottomSheetWidget extends StatefulWidget {
  const PaymentMethodBottomSheetWidget({super.key});

  @override
  State<PaymentMethodBottomSheetWidget> createState() =>
      _PaymentMethodBottomSheetWidgetState();
}

class _PaymentMethodBottomSheetWidgetState
    extends State<PaymentMethodBottomSheetWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: Dimensions.paddingSizeSmall,
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: GetBuilder<MyAccountController>(
        builder: (myAccountController) {
          final paymentMethods = PaymentMethodFilterHelper.nonKeepzMethods(
            Get.find<SplashController>().configModel?.activePaymentMethodList,
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'payment_method'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Row(
                    children: [
                      Text(
                        'pay_via_online'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),

                      Flexible(
                        child: Text(
                          '(${'faster_and_secure_way_to_pay_bill'.tr})',
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ListView.builder(
                    itemCount: paymentMethods.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final method = paymentMethods[index];

                      bool isSelected =
                          myAccountController.paymentIndex == 1 &&
                          method.getWay ==
                              myAccountController.digitalPaymentName;

                      return InkWell(
                        onTap: () {
                          myAccountController.setPaymentIndex(1);
                          myAccountController.changeDigitalPaymentName(
                            method.getWay!,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeSmall,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusDefault,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).disabledColor.withValues(alpha: 0.4),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: Dimensions.paddingSizeLarge,
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 20,
                                width: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.green
                                      : Theme.of(context).cardColor,
                                  border: Border.all(
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Theme.of(context).cardColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(
                                width: Dimensions.paddingSizeDefault,
                              ),

                              Text(
                                method.getWayTitle!,
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              const Spacer(),

                              CustomImageWidget(
                                height: 20,
                                fit: BoxFit.contain,
                                image: '${method.getWayImageFullUrl}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault,
                  ),
                  child: CustomButtonWidget(
                    radius: Dimensions.radiusDefault,
                    buttonText: 'select'.tr,
                    onPressed: () {
                      if (paymentMethods.isEmpty) {
                        return;
                      }

                      final bool hasSelectedMethod = paymentMethods.any(
                        (method) =>
                            method.getWay ==
                            myAccountController.digitalPaymentName,
                      );
                      if (!hasSelectedMethod) {
                        myAccountController.setPaymentIndex(1);
                        myAccountController.changeDigitalPaymentName(
                          paymentMethods.first.getWay!,
                          canUpdate: false,
                        );
                      }

                      double amount = Get.find<ProfileController>()
                          .profileModel!
                          .payableBalance!;
                      myAccountController.makeCollectCashPayment(
                        amount,
                        myAccountController.digitalPaymentName!,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
