import 'package:sixam_mart_delivery/util/typography.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TitleWidget extends StatelessWidget {
  final String title;
  final Function? onTap;
  final bool showOrderCount;
  final int? orderCount;
  const TitleWidget({
    super.key,
    required this.title,
    this.onTap,
    this.showOrderCount = false,
    this.orderCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  semanticsLabel: title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MiliTypography.heading,
                ),
              ),
              if (showOrderCount)
                Text(
                  ' ($orderCount)',
                  style: robotoRegular.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
            ],
          ),
        ),

        onTap != null
            ? InkWell(
                onTap: onTap as void Function()?,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 0, 5),
                  child: Text(
                    'see_all'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
