import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class CustomButtonWidget extends StatelessWidget {
  final Function? onPressed;
  final String buttonText;
  final bool transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double radius;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? fontColor;
  final bool isLoading;
  final bool isBold;
  final bool isBorder;
  final Color? disabledColor;
  final Color? disabledFontColor;
  final double borderWidth;
  final Color? borderColor;
  final Color? textColor;
  const CustomButtonWidget({
    super.key,
    this.onPressed,
    required this.buttonText,
    this.transparent = false,
    this.margin,
    this.width,
    this.height,
    this.fontSize,
    this.radius = 10,
    this.icon,
    this.backgroundColor,
    this.fontColor,
    this.isLoading = false,
    this.isBold = true,
    this.isBorder = false,
    this.disabledColor,
    this.disabledFontColor,
    this.borderColor,
    this.borderWidth = 1,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      backgroundColor: onPressed == null
          ? (disabledColor ??
                Theme.of(context).disabledColor.withValues(alpha: 0.5))
          : transparent
          ? Colors.transparent
          : backgroundColor ?? Theme.of(context).primaryColor,
      minimumSize: Size(width ?? Dimensions.webMaxWidth, height ?? 50),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: isBorder
            ? BorderSide(
                color:
                    borderColor ??
                    Theme.of(context).disabledColor.withValues(alpha: 0.5),
                width: borderWidth,
              )
            : BorderSide.none,
      ),
    );

    return Center(
      child: SizedBox(
        width: width ?? Dimensions.webMaxWidth,
        child: Padding(
          padding: margin ?? EdgeInsets.zero,
          child: TextButton(
            onPressed: isLoading ? null : onPressed as void Function()?,
            style: flatButtonStyle,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Keep the label's layout while busy so the action never jumps.
                ExcludeSemantics(
                  excluding: isLoading,
                  child: Opacity(
                    opacity: isLoading ? 0 : 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: transparent
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).cardColor,
                          ),
                          const SizedBox(
                            width: Dimensions.paddingSizeExtraSmall,
                          ),
                        ],
                        Flexible(
                          child: Text(
                            buttonText,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: (isBold ? robotoBold : robotoRegular)
                                .copyWith(
                                  color: onPressed == null
                                      ? (disabledFontColor ??
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge!.color)
                                      : fontColor ??
                                            (transparent
                                                ? Theme.of(context).primaryColor
                                                : Colors.white),
                                  fontSize:
                                      fontSize ?? Dimensions.fontSizeLarge,
                                  height: 1.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Semantics(
                      label: 'loading'.tr,
                      liveRegion: true,
                      child: Center(
                        child: MediaQuery.disableAnimationsOf(context)
                            ? Icon(
                                Icons.hourglass_top_rounded,
                                color:
                                    fontColor ??
                                    textColor ??
                                    (transparent
                                        ? Theme.of(context).primaryColor
                                        : Colors.white),
                                size: 20,
                              )
                            : SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color:
                                      fontColor ??
                                      textColor ??
                                      (transparent
                                          ? Theme.of(context).primaryColor
                                          : Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
