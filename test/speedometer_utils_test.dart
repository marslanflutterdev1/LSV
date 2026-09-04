import 'package:flutter_test/flutter_test.dart';
import 'package:satellite_view/features/home/speedo_meter/speedometer_utils.dart';

void main() {
  group('Speedometer utilities', () {
    test('gear label returns neutral for stationary speed', () {
      expect(gearLabelForSpeed(0), 'N');
      expect(gearLabelForSpeed(4.9), 'N');
    });

    test('gear label changes by speed range', () {
      expect(gearLabelForSpeed(5), '1');
      expect(gearLabelForSpeed(25), '2');
      expect(gearLabelForSpeed(55), '3');
      expect(gearLabelForSpeed(90), '4');
      expect(gearLabelForSpeed(130), '5');
      expect(gearLabelForSpeed(180), '6');
    });

    test('speed formatting clamps and rounds to integer display', () {
      expect(formatSpeedLabel(-5), '0');
      expect(formatSpeedLabel(12.4), '12');
      expect(formatSpeedLabel(244), '240');
    });

    test('rpm display stays at zero when speed is idle', () {
      expect(rpmLabelForSpeed(0), '0');
      expect(rpmLabelForSpeed(20), '800');
    });

    test('signal quality text is derived from accuracy', () {
      expect(signalQualityFromAccuracy(2.5), 'Excellent');
      expect(signalQualityFromAccuracy(8), 'Good');
      expect(signalQualityFromAccuracy(20), 'Fair');
      expect(signalQualityFromAccuracy(100), 'Weak');
    });

    test('trip and average formatting are readable and consistent', () {
      expect(formatDistanceLabel(0.09), '0.09 km');
      expect(formatDistanceLabel(12.34), '12.3 km');
      expect(formatAverageSpeedLabel(72.8), '73 km/h');
      expect(formatTopSpeedLabel(88.5), '89 km/h');
      expect(formatCoordinateLabel(31.5355), '31.5355');
      expect(averageSpeedKmhForTrip(10, 3600), 10);
      expect(averageSpeedKmhForTrip(0, 300), 0);
    });

    test('top speed history keeps newest peaks and preserves serialization', () {
      final history = updateTopSpeedHistory([70, 65], 75);

      expect(history.first, 75);
      expect(history.length, 3);
      expect(history, [75, 70, 65]);

      final trimmed = updateTopSpeedHistory(List<double>.filled(5, 60), 55, maxEntries: 3);
      expect(trimmed.length, 3);
      expect(trimmed, [55, 60, 60]);

      final encoded = encodeTopSpeedHistory([75, 70]);
      expect(encoded, '[75,70]');
      expect(decodeTopSpeedHistory(encoded), [75, 70]);
      expect(decodeTopSpeedHistory(null), isEmpty);
    });
  });
}
