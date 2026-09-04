import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarker {
  CustomMarker._();

  static Future<BitmapDescriptor> setMarker({
    required String path,
    int? targetWidth,
    int? targetHeight,
  }) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? imageData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (imageData == null) {
      throw StateError('Failed to decode marker asset: $path');
    }

    final Uint8List image = imageData.buffer.asUint8List();
    return BitmapDescriptor.bytes(image);
  }
}