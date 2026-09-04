import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutePolylineSegments {
  const RoutePolylineSegments({
    required this.completed,
    required this.remaining,
  });

  final List<LatLng> completed;
  final List<LatLng> remaining;
}

RoutePolylineSegments splitRoutePolyline({
  required List<LatLng> routeCoordinates,
  required LatLng currentLocation,
}) {
  if (routeCoordinates.length < 2) {
    return const RoutePolylineSegments(completed: [], remaining: []);
  }

  final projection = _nearestSegment(routeCoordinates, currentLocation);
  final start = routeCoordinates[projection.index];
  final end = routeCoordinates[projection.index + 1];
  final projectedPoint = _interpolatePoint(
    start,
    end,
    projection.progress,
  );

  final completed = <LatLng>[];
  if (projection.index > 0) {
    completed.addAll(routeCoordinates.take(projection.index));
  }

  completed.add(start);
  if (projection.progress > 0) {
    completed.add(projectedPoint);
  }

  final remaining = <LatLng>[];
  final shouldAddCurrentPoint =
      projection.progress < 1 || projection.index == 0;

  if (shouldAddCurrentPoint) {
    remaining.add(projection.progress > 0 ? projectedPoint : start);
  }

  remaining.addAll(routeCoordinates.skip(projection.index + 1));

  return RoutePolylineSegments(
    completed: completed,
    remaining: remaining,
  );
}

class _SegmentProjection {
  const _SegmentProjection({
    required this.index,
    required this.progress,
    required this.distance,
  });

  final int index;
  final double progress;
  final double distance;
}

_SegmentProjection _nearestSegment(
  List<LatLng> routeCoordinates,
  LatLng currentLocation,
) {
  double bestDistance = double.infinity;
  int bestIndex = 0;
  double bestProgress = 0.0;

  for (var index = 0; index < routeCoordinates.length - 1; index++) {
    final start = routeCoordinates[index];
    final end = routeCoordinates[index + 1];

    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;
    final px = currentLocation.longitude - start.longitude;
    final py = currentLocation.latitude - start.latitude;

    final segmentLengthSquared = dx * dx + dy * dy;
    final progress = segmentLengthSquared == 0
        ? 0.0
        : ((px * dx) + (py * dy)) / segmentLengthSquared;
    final clampedProgress = progress.clamp(0.0, 1.0);

    final projectionLat = start.latitude + (dy * clampedProgress);
    final projectionLng = start.longitude + (dx * clampedProgress);
    final distanceSquared =
        (currentLocation.latitude - projectionLat) *
            (currentLocation.latitude - projectionLat) +
        (currentLocation.longitude - projectionLng) *
            (currentLocation.longitude - projectionLng);

    final distance = math.sqrt(distanceSquared);

    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = index;
      bestProgress = clampedProgress;
    }
  }

  return _SegmentProjection(
    index: bestIndex,
    progress: bestProgress,
    distance: bestDistance,
  );
}

LatLng _interpolatePoint(LatLng start, LatLng end, double progress) {
  return LatLng(
    start.latitude + (end.latitude - start.latitude) * progress,
    start.longitude + (end.longitude - start.longitude) * progress,
  );
}
