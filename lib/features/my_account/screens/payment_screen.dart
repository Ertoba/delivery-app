import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/my_account/controllers/my_account_controller.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/models/collect_cash_payment.dart';
import 'package:sixam_mart_delivery/features/my_account/widgets/collect_cash_payment_sheet.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

/// Compatibility for an existing payment route. New cash transfers are owned
/// by PaymentMethodBottomSheetWidget and never navigate here.
class PaymentScreen extends StatelessWidget {
  final String? redirectUrl;
  const PaymentScreen({super.key, this.redirectUrl});

  @override
  Widget build(BuildContext context) {
    CollectCashPayment? payment;
    try {
      final uri = Uri.parse(redirectUrl ?? '');
      final id = uri.queryParameters['payment_id'];
      payment = CollectCashPayment.fromJson({
        'redirect_link': redirectUrl,
        'payment_id': id,
        'status_url': Uri.parse(AppConstants.baseUrl)
            .replace(
              path: CollectCashPayment.statusPath,
              queryParameters: {'payment_id': id ?? ''},
            )
            .toString(),
      }, Uri.parse(AppConstants.baseUrl));
    } on FormatException {
      // Invalid/old links must never regain redirect-as-success behavior.
    }
    final controller = Get.find<MyAccountController>();
    return Scaffold(
      body: SafeArea(
        child: payment == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('cash_payment_unavailable'.tr),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('okay'.tr),
                    ),
                  ],
                ),
              )
            : CollectCashPaymentSheet(
                payment: payment,
                verify: controller.getCollectCashPaymentStatus,
                refreshAccount: controller.refreshSettledCashPayment,
              ),
      ),
    );
  }
}
