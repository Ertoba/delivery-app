# Mili AGP 9 compatibility patch

This directory is an exact copy of `flutter_inappwebview_android` 1.1.3 with
the Android default ProGuard file changed from `proguard-android.txt` to
`proguard-android-optimize.txt`. AGP 9 rejects the former file.

No plugin runtime source code is changed.
