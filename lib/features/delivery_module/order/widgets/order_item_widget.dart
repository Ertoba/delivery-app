import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/image_cache_helper.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_image_widget.dart';

class OrderItemWidget extends StatelessWidget {
  final OrderModel order;
  final OrderDetailsModel orderDetails;
  const OrderItemWidget({super.key, required this.order, required this.orderDetails});
  
  @override
  Widget build(BuildContext context) {
    String addOnText = '';
    for (var addOn in orderDetails.addOns!) {
      addOnText = '$addOnText${(addOnText.isEmpty) ? '' : ',  '}${addOn.name} (${addOn.quantity})';
    }

    String? variationText = '';
    if(orderDetails.variation!.isNotEmpty) {
      final String variationType = orderDetails.variation![0].type ?? '';
      final List<ChoiceOptions> choiceOptions = orderDetails.itemDetails?.choiceOptions ?? [];
      // Map the ordered variation type (e.g. "BBQ-soy-free") back to each choice's selected value.
      // Splitting on '-' is unsafe because an option value can itself contain '-' (e.g. "soy-free"),
      // so match each choice's options against the type string instead.
      final List<String>? values = _matchVariationValues(variationType, choiceOptions);
      if(values != null && values.length == choiceOptions.length) {
        int index = 0;
        for (var choice in choiceOptions) {
          variationText = '${variationText!}${(index == 0) ? '' : ',  '}${choice.title} - ${values[index]}';
          index = index + 1;
        }
      }else {
        // Fallback: show the ordered variation type itself (never the first *available* variation).
        variationText = variationType;
      }
    }else if(orderDetails.foodVariation!.isNotEmpty) {
      for(FoodVariation variation in orderDetails.foodVariation!) {
        variationText = '${variationText!}${variationText.isNotEmpty ? ', ' : ''}${variation.name} (';
        for(VariationValue value in variation.variationValues!) {
          variationText = '${variationText!}${variationText.endsWith('(') ? '' : ', '}${value.level}';
        }
        variationText = '${variationText!})';
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Text('item_info'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
      // SizedBox(height: Dimensions.paddingSizeSmall),
      Row(children: [
        orderDetails.itemDetails!.imageFullUrl != null ? ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: CustomImageWidget(
            height: 50, width: 50, fit: BoxFit.cover, cacheWidth: context.cacheSize(50),
            image: '${orderDetails.itemDetails!.imageFullUrl}',
          ),
        ) : CustomImageWidget(
          height: 50, width: 50, fit: BoxFit.cover,
          image: Images.pictureIcon, cacheWidth: context.cacheSize(50),
        ),
        SizedBox(width:  Dimensions.paddingSizeSmall),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(children: [
              Expanded(child: Text(
                orderDetails.itemDetails!.name!,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              )),
              Text('${'quantity'.tr}:', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
              Text(orderDetails.quantity.toString(), style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
            ]),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Row(children: [
              Text(PriceConverterHelper.convertPrice(orderDetails.price! - orderDetails.discountOnItem!), style: robotoMedium),
              const SizedBox(width: 5),

              orderDetails.discountOnItem! > 0 ? Expanded(child: Text(
                PriceConverterHelper.convertPrice(orderDetails.price),
                style: robotoMedium.copyWith(decoration: TextDecoration.lineThrough, fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              )) : const Expanded(child: SizedBox()),

              ((Get.find<SplashController>().getModule(order.moduleType).unit! && orderDetails.itemDetails!.unitType != null)
              || (Get.find<SplashController>().configModel!.toggleVegNonVeg! && Get.find<SplashController>().getModule(order.moduleType).vegNonVeg!)) ? Container(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                child: Text(
                  Get.find<SplashController>().getModule(order.moduleType).unit! ? orderDetails.itemDetails!.unitType ?? ''
                      : orderDetails.itemDetails!.veg == 0 ? 'non_veg'.tr : 'veg'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
                ),
              ) : const SizedBox(),

            ]),

          ]),
        ),
      ]),

      (Get.find<SplashController>().getModule(order.moduleType).addOn! && addOnText.isNotEmpty) ? Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          const SizedBox(width: 60),
          Text('${'addons'.tr}: ', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
          Flexible(child: Text(addOnText, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
        ]),
      ) : const SizedBox(),

      variationText!.isNotEmpty ? Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          const SizedBox(width: 60),
          Text('${'variations'.tr}: ', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
          Flexible(child: Text(variationText, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
        ]),
      ) : const SizedBox(),
    ]);
  }

  // Reconstructs the selected value for each choice option from an ordered variation `type`
  // string (option values joined by '-'), tolerating option values that themselves contain '-'
  // (e.g. "soy-free"). Returns null if the type can't be cleanly mapped to the choice options.
  List<String>? _matchVariationValues(String type, List<ChoiceOptions> choiceOptions) {
    if (choiceOptions.isEmpty || type.isEmpty) return null;
    String remaining = type;
    final List<String> values = [];
    for (int i = 0; i < choiceOptions.length; i++) {
      final bool isLast = i == choiceOptions.length - 1;
      // Try the longest option first so a multi-hyphen value wins over a shorter prefix.
      final List<String> options = (choiceOptions[i].options ?? [])
          .map((o) => o.trim()).where((o) => o.isNotEmpty).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      String? found;
      for (final opt in options) {
        if (isLast ? remaining == opt : remaining.startsWith('$opt-')) {
          found = opt;
          break;
        }
      }
      if (found == null) return null;
      values.add(found);
      remaining = isLast ? '' : remaining.substring(found.length + 1);
    }
    return remaining.isEmpty ? values : null;
  }
}
