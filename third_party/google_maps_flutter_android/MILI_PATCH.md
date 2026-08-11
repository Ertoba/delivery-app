# MILI Android patch

Source: `google_maps_flutter_android` 2.18.2.

Marker assets and byte data are decoded with `BitmapFactory.Options` and a
power-of-two `inSampleSize` derived from the requested marker dimensions. The
public Flutter API and final marker dimensions are unchanged.
