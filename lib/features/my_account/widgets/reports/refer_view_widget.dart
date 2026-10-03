import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart_delivery/features/my_account/controllers/my_account_controller.dart';
import 'package:sixam_mart_delivery/features/my_account/widgets/reports/earning_report_card.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
class ReferViewWidget extends StatelessWidget {
  final MyAccountController myAccountController;
  const ReferViewWidget({super.key, required this.myAccountController});

  @override
  Widget build(BuildContext context) {
    // Returns a sliver (hosted inside my_earning_screen's CustomScrollView) so the paginated,
    // growing referral list builds lazily instead of eagerly via shrinkWrap.
    return myAccountController.referralEarningsList != null ? myAccountController.referralEarningsList!.isNotEmpty ? SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return EarningReportCard(
            index: index,
            myAccountController: myAccountController,
            earning: null,
            refrealEarnings: myAccountController.referralEarningsList![index],
            loyalityPoints: null,
            createdAt: myAccountController.referralEarningsList![index].createdAt!,
            showDivider: index != myAccountController.referralEarningsList!.length - 1,
          );
        },
        childCount: myAccountController.referralEarningsList!.length,
      ),
    ) : SliverToBoxAdapter(child: Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Text(
          'no_earning_found'.tr,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
        ),
      ),
    )) : const SliverToBoxAdapter(child: Center(child: Padding(
      padding: EdgeInsets.all(Dimensions.paddingSizeLarge), child: CircularProgressIndicator(),
    )));
  }
}
