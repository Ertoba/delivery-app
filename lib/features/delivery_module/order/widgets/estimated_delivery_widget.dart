import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:sixam_mart_delivery/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class OrderEtaHelper {
  const OrderEtaHelper._();

  static EtaModel? resolve(OrderModel? order, EtaModel? detailsEta) {
    if (_hasWindow(detailsEta)) {
      return detailsEta;
    }
    if (_hasWindow(order?.eta)) {
      return order!.eta;
    }
    return null;
  }

  static bool _hasWindow(EtaModel? eta) => eta?.window != null && eta!.window!.trim().isNotEmpty;

  static String? windowText(EtaModel? eta) {
    final String? window = eta?.window?.trim();
    return (window == null || window.isEmpty) ? null : window;
  }

  static String? dateText(EtaModel? eta) {
    if (eta == null) return null;
    final String? from = dayLabel(eta.fromAt);
    final String? to = dayLabel(eta.toAt);
    if (from == null) return to;
    if (to == null || to == from) return from;
    return '$from - $to';
  }

  static String? dayLabel(String? stamp) {
    final DateTime? day = _dateOnly(stamp);
    if (day == null) return null;

    final DateTime now = DateTime.now();
    final int diff = day.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return _tr('today', 'Today');
    if (diff == 1) return _tr('tomorrow', 'Tomorrow');
    return DateFormat('dd MMM').format(day);
  }

  static String _tr(String key, String fallback) {
    final String value = key.tr;
    return value == key ? fallback : value;
  }

  /// Date portion only - never the clock, never a timezone shift.
  static DateTime? _dateOnly(String? stamp) {
    if (stamp == null || stamp.length < 10) return null;
    try {
      return DateTime.parse(stamp.substring(0, 10));
    } catch (_) {
      return null;
    }
  }
}

/// Arrival window card on the order details screen.
///
/// Renders nothing at all when the server sent no ETA - that `null` means the
/// platform was never configured to make a promise for this order, so the app
/// must not invent one.
class EstimatedDeliveryWidget extends StatelessWidget {
  final OrderModel order;
  final EtaModel? detailsEta;

  const EstimatedDeliveryWidget({super.key, required this.order, this.detailsEta});

  @override
  Widget build(BuildContext context) {
    final EtaModel? eta = OrderEtaHelper.resolve(order, detailsEta);
    final String? window = OrderEtaHelper.windowText(eta);
    if (window == null) {
      return const SizedBox();
    }
    final String? date = OrderEtaHelper.dateText(eta);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        boxShadow: Get.isDarkMode ? null : [BoxShadow(color: Colors.grey[200]!, spreadRadius: 1, blurRadius: 5)],
      ),
      child: Row(children: [
        CustomAssetImageWidget(
          image: Images.clockIcon,
          height: 30, width: 30, fit: BoxFit.contain,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('estimated_delivery_time'.tr, style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor,
          )),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Text(
            window,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            textDirection: TextDirection.ltr,
          ),

          if(date != null) ...[
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(date, style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor,
            )),
          ],
        ])),
      ]),
    );
  }
}
