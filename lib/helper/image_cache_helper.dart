import 'package:flutter/widgets.dart';

/// Helpers for decoding images at the size they are actually painted at,
/// instead of at their full source resolution.
///
/// `Image.asset`, `Image.network` and `ResizeImage` take `cacheWidth` and
/// `cacheHeight` in **physical pixels**, while layout sizes are in logical
/// pixels (dp). Multiplying by the device pixel ratio bridges the two: a
/// 1000x1000 source painted into a 100dp box decodes at 300x300 on a 3x screen
/// instead of 1000x1000, cutting that image's memory footprint by roughly 90%.
class ImageCacheHelper {
  ImageCacheHelper._();

  /// Converts a logical (dp) [size] into physical pixels, for use with
  /// `cacheWidth` / `cacheHeight`.
  ///
  /// Returns `null` when [size] is null, zero, negative or unbounded (the
  /// `double.infinity` an `Expanded` or unconstrained box reports). `null`
  /// tells Flutter to decode at full resolution, which is the safe fallback.
  ///
  /// Pass the result to **only one** of `cacheWidth` or `cacheHeight`.
  /// Supplying both forces an exact decode size and stretches the image
  /// whenever the target box does not match the source aspect ratio.
  static int? cacheSize(BuildContext context, double? size) {
    if (size == null || !size.isFinite || size <= 0) {
      return null;
    }
    return (size * MediaQuery.devicePixelRatioOf(context)).round();
  }
}

extension ImageCacheSizeExtension on BuildContext {
  /// Shorthand for [ImageCacheHelper.cacheSize], e.g.
  /// `Image.asset(path, width: 100, cacheWidth: context.cacheSize(100))`.
  int? cacheSize(double? size) => ImageCacheHelper.cacheSize(this, size);
}
