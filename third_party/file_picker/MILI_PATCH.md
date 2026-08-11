# MILI Android patch

Source: `file_picker` 10.3.7.

The Android image-compression path decodes bounds first and supplies
`BitmapFactory.Options.inSampleSize` for images larger than 4096 pixels. This
is the upstream fix from commit `8d8713f69d5d47a28724678fbf189bfae0d5f5c2`.
