import 'dart:convert';
import 'dart:math';

double clampSpeedValue(double speedKmh) => speedKmh.clamp(0.0, 240.0);

String formatSpeedLabel(double speedKmh) => clampSpeedValue(speedKmh).round().toString();

String rpmLabelForSpeed(double speedKmh) {
  final clamped = clampSpeedValue(speedKmh);
  if (clamped <= 0) {
    return '0';
  }

  return '${(clamped * 40).round()}';
}

String gearLabelForSpeed(double speedKmh) {
  final clamped = clampSpeedValue(speedKmh);

  if (clamped < 5) {
    return 'N';
  }
  if (clamped < 20) {
    return '1';
  }
  if (clamped < 40) {
    return '2';
  }
  if (clamped < 70) {
    return '3';
  }
  if (clamped < 110) {
    return '4';
  }
  if (clamped < 150) {
    return '5';
  }

  return '6';
}

String signalQualityFromAccuracy(double? accuracyInMeters) {
  if (accuracyInMeters == null || accuracyInMeters.isNaN || accuracyInMeters < 0) {
    return 'Unknown';
  }

  if (accuracyInMeters <= 5) {
    return 'Excellent';
  }
  if (accuracyInMeters <= 12) {
    return 'Good';
  }
  if (accuracyInMeters <= 25) {
    return 'Fair';
  }

  return 'Weak';
}

String formatDistanceLabel(double distanceKm) {
  if (distanceKm < 0.1) {
    return '${distanceKm.toStringAsFixed(2)} km';
  }
  if (distanceKm < 100) {
    return '${distanceKm.toStringAsFixed(1)} km';
  }
  return '${distanceKm.toStringAsFixed(0)} km';
}

String formatAverageSpeedLabel(double speedKmh) {
  return '${clampSpeedValue(speedKmh).round()} km/h';
}

String formatTopSpeedLabel(double speedKmh) {
  return '${clampSpeedValue(speedKmh).round()} km/h';
}

String formatCoordinateLabel(double coordinate) {
  return coordinate.toStringAsFixed(4);
}

double averageSpeedKmhForTrip(double distanceKm, int movingSeconds) {
  if (distanceKm <= 0 || movingSeconds <= 0) {
    return 0;
  }

  return clampSpeedValue(distanceKm / (movingSeconds / 3600));
}

double distanceBetweenCoordinates({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusMeters = 6371000.0;

  final lat1Radians = lat1 * pi / 180;
  final lon1Radians = lon1 * pi / 180;
  final lat2Radians = lat2 * pi / 180;
  final lon2Radians = lon2 * pi / 180;

  final deltaLat = lat2Radians - lat1Radians;
  final deltaLon = lon2Radians - lon1Radians;

  final haversine = sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1Radians) * cos(lat2Radians) * sin(deltaLon / 2) * sin(deltaLon / 2);

  final angularDistance = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));
  return earthRadiusMeters * angularDistance;
}

List<double> updateTopSpeedHistory(
  List<double> history,
  double newTopSpeed, {
  int maxEntries = 10,
}) {
  final nextHistory = <double>[];

  final normalized = clampSpeedValue(newTopSpeed);
  if (normalized > 0) {
    nextHistory.add(normalized);
  }

  nextHistory.addAll(history.map(clampSpeedValue));

  if (nextHistory.length > maxEntries) {
    nextHistory.removeRange(maxEntries, nextHistory.length);
  }

  return nextHistory;
}

String encodeTopSpeedHistory(List<double> history) {
  return jsonEncode(history.map((speed) => speed.round()).toList());
}

List<double> decodeTopSpeedHistory(String? rawHistory) {
  if (rawHistory == null || rawHistory.trim().isEmpty) {
    return <double>[];
  }

  try {
    final decoded = jsonDecode(rawHistory);
    if (decoded is! List) {
      return <double>[];
    }

    return decoded
        .map<double>((value) => (value as num).toDouble())
        .toList(growable: false);
  } catch (_) {
    return <double>[];
  }
}
