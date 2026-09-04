import 'package:satellite_view/local/local_sp.dart';

class AdFrequencyManager {
  AdFrequencyManager._();

  static Future<bool> shouldShowAd(
    String key, {
    int? fx,
  }) async {
    final currentCount = LocalSP.getIntData(key);
    final newCount = currentCount + 1;
    await LocalSP.setIntData(key, newCount);

    final interval = fx ?? 2;

    return newCount % interval == 0;
  }

  static Future<void> reset(String key) async {
    await LocalSP.setIntData(key, 0);
  }

}