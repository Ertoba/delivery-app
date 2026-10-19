import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/bogo_order_item_widget.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

/// Lines that share a `bundleGroupId` are one bundle package to the customer, so they
/// are folded into a single card instead of loose rows that look like separate
/// purchases — mirrors [BogoOrderItemGroup] in bogo_order_item_widget.dart.
class BundleOrderItemGroup {
  final String groupId;
  final List<OrderDetailsModel> items;
  const BundleOrderItemGroup({required this.groupId, required this.items});
}

/// Groups the already-BOGO-grouped list further: any plain [OrderDetailsModel] carrying
/// a `bundleGroupId` is folded into a [BundleOrderItemGroup], preserving first-seen
/// order. [BogoOrderItemGroup] entries pass through untouched — a line cannot be both,
/// and anything that is neither stays exactly as it was.
List<Object> groupBundleOrderDetails(List<Object> items) {
  final List<Object> result = [];
  final Map<String, BundleOrderItemGroup> groupsById = {};

  for(final Object entry in items) {
    if(entry is! OrderDetailsModel || !entry.isBundleItem) {
      result.add(entry);
      continue;
    }

    final String groupId = entry.bundleGroupId!;
    BundleOrderItemGroup? group = groupsById[groupId];
    if(group == null) {
      group = BundleOrderItemGroup(groupId: groupId, items: []);
      groupsById[groupId] = group;
      result.add(group);
    }
    group.items.add(entry);
  }

  return result;
}


class BundleOrderItemWidget extends StatelessWidget {
  final BundleOrderItemGroup group;
  const BundleOrderItemWidget({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final OrderDetailsModel? primary = group.items.isNotEmpty ? group.items.first : null;
    final double totalPrice = group.items.fold(0.0, (sum, item) => sum + ((item.price ?? 0) * (item.quantity ?? 1)));
    /// Total units to hand over, summed across members — the same measure
    /// [BogoOrderItemWidget] shows for its buying items.
    final int totalQty = group.items.fold(0, (sum, item) => sum + (item.quantity ?? 0));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Row(children: [
        Expanded(child: Text(
          primary?.bundleName ?? primary?.itemDetails?.name ?? '',
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        )),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Text('${'quantity'.tr}:', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
        Text(totalQty.toString(), style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
      ]),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      Text(PriceConverterHelper.convertPrice(totalPrice), style: robotoMedium, textDirection: TextDirection.ltr),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      _BundleItemThumbnails(items: group.items),

    ]);
  }
}


class _BundleItemThumbnails extends StatelessWidget {
  final List<OrderDetailsModel> items;
  const _BundleItemThumbnails({required this.items});

  static const double _size = 48;
  static const double _overlap = 26;
  static const int _maxVisible = 3;

  @override
  Widget build(BuildContext context) {
    final List<String> thumbnails = items.map((item) => item.itemDetails?.imageFullUrl ?? '').toList();
    final List<String> visible = thumbnails.take(_maxVisible).toList();
    final int overflow = thumbnails.length - visible.length;
    final int cardCount = visible.length + (overflow > 0 ? 1 : 0);

    return visible.isEmpty ? const SizedBox() : SizedBox(
      height: _size,
      width: _size + (cardCount - 1) * _overlap,
      child: Stack(children: [
        ...List.generate(visible.length, (index) => Positioned(
          left: index * _overlap,
          child: Container(
            width: _size, height: _size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusMedium)),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              border: Border.all(color: Theme.of(context).cardColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              child: CustomImageWidget(
                image: visible[index].isNotEmpty ? visible[index] : Images.pictureIcon,
                height: _size, width: _size, fit: BoxFit.cover,
              ),
            ),
          ),
        )),

        if(overflow > 0) Positioned(
          left: visible.length * _overlap,
          child: Container(
            height: _size, width: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              border: Border.all(color: Theme.of(context).cardColor, width: 2),
            ),
            child: Text('+$overflow', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
          ),
        ),
      ]),
    );
  }
}
