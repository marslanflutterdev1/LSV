import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:satellite_view/features/home/route_finder/route_polyline_segments.dart';

void main() {
  test('splits a route into completed and remaining segments', () {
    const route = [
      LatLng(0, 0),
      LatLng(0, 10),
      LatLng(10, 10),
    ];

    final split = splitRoutePolyline(
      routeCoordinates: route,
      currentLocation: const LatLng(0, 4),
    );

    expect(split.completed, const [
      LatLng(0, 0),
      LatLng(0, 4),
    ]);

    expect(split.remaining, const [
      LatLng(0, 4),
      LatLng(0, 10),
      LatLng(10, 10),
    ]);
  });

  test('keeps the remaining route empty when the current point is on the last segment end', () {
    const route = [
      LatLng(0, 0),
      LatLng(0, 10),
      LatLng(10, 10),
    ];

    final split = splitRoutePolyline(
      routeCoordinates: route,
      currentLocation: const LatLng(10, 10),
    );

    expect(split.completed, const [
      LatLng(0, 0),
      LatLng(0, 10),
      LatLng(10, 10),
    ]);
    expect(split.remaining, const [
      LatLng(10, 10),
    ]);
  });
}
