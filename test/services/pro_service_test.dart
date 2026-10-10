import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/services/pro_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProState.canAddFamily', () {
    test('無料は3人まで', () {
      const s = ProState();
      expect(s.canAddFamily(2), isTrue);
      expect(s.canAddFamily(3), isFalse);
    });
    test('Pro と以前からの利用者は無制限', () {
      expect(const ProState(isPro: true).canAddFamily(10), isTrue);
      expect(const ProState(isLegacy: true).canAddFamily(10), isTrue);
    });
  });

  group('markLegacyUserOnce', () {
    test('初回設定済みで印が無い = 以前からの利用者', () async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      await ProState.markLegacyUserOnce(prefs);
      expect(prefs.getBool('legacy_user'), isTrue);
    });
    test('新しく入れた人は false。あとで初回設定を終えても変わらない', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await ProState.markLegacyUserOnce(prefs);
      await prefs.setBool('onboarding_completed', true);
      await ProState.markLegacyUserOnce(prefs);
      expect(prefs.getBool('legacy_user'), isFalse);
    });
  });
}
