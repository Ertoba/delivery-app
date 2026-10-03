import 'package:cached_network_image/cached_network_image.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:flutter/cupertino.dart';

class CustomImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool isNotification;
  final int? cacheWidth;
  final int? cacheHeight;

  const CustomImageWidget({
    super.key, required this.image, this.height, this.width,
    this.fit = BoxFit.cover, this.isNotification = false,
    this.cacheWidth, this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final String placeholderImage = isNotification ? Images.notificationPlaceholder : Images.placeholder;

    Widget placeholderWidget() => Image.asset(
      placeholderImage, height: height, width: width, fit: fit,
      cacheWidth: cacheWidth, cacheHeight: cacheHeight,
    );

    return CachedNetworkImage(
      imageUrl: image, height: height, width: width, fit: fit,
      memCacheWidth: cacheWidth, memCacheHeight: cacheHeight,
      placeholder: (context, url) => placeholderWidget(),
      errorWidget: (context, url, error) => placeholderWidget(),
    );
  }
}
