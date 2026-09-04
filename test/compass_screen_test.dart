import 'package:flutter_test/flutter_test.dart';
import 'package:satellite_view/features/home/compass/compass_screen.dart';

void main() {
  test('returns north at the top of the compass', () {
    expect(getCardinalDirection(0), 'N');
    expect(getCardinalDirection(359.9), 'N');
  });

  test('returns cardinal directions in the correct quadrants', () {
    expect(getCardinalDirection(45), 'NE');
    expect(getCardinalDirection(90), 'E');
    expect(getCardinalDirection(180), 'S');
    expect(getCardinalDirection(270), 'W');
    expect(getCardinalDirection(315), 'NW');
  });
}
