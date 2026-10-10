import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_settings_provider.dart';
import '../utils/prefs_keys.dart';

/// LifeCounter Pro（買い切り・ファミリー共有あり）
const proProductId = 'lifecounter.pro';

/// 無料で登録できる家族の人数
const freeFamilyLimit = 3;

class ProState {
  const ProState({
    this.isPro = false,
    this.isLegacy = false,
    this.price,
    this.busy = false,
  });

  /// Pro を購入済み（ファミリー共有で受け取った場合も含む）
  final bool isPro;

  /// v1.2 より前から使っている人。家族の登録は無制限のまま（v1.0.2 で上限を外したため）
  final bool isLegacy;

  /// ストアの表示価格（取得できなければ null）
  final String? price;

  /// 購入・復元の処理中
  final bool busy;

  /// 以前からの利用者かを、起動直後(オンボーディングより前)に一度だけ決める。
  /// 判定の印が無いのに初回設定が済んでいる = この版より前から使っている。
  /// 新しく入れた人は、ここでは初回設定が済んでいないので false になる
  static Future<void> markLegacyUserOnce(SharedPreferences prefs) async {
    if (prefs.containsKey(PrefsKeys.legacyUser)) return;
    final onboarded = prefs.getBool(PrefsKeys.onboardingCompleted) ?? false;
    await prefs.setBool(PrefsKeys.legacyUser, onboarded);
  }

  bool canAddFamily(int currentCount) =>
      isPro || isLegacy || currentCount < freeFamilyLimit;

  ProState copyWith({bool? isPro, bool? isLegacy, String? price, bool? busy}) =>
      ProState(
        isPro: isPro ?? this.isPro,
        isLegacy: isLegacy ?? this.isLegacy,
        price: price ?? this.price,
        busy: busy ?? this.busy,
      );
}

final proProvider = NotifierProvider<ProNotifier, ProState>(ProNotifier.new);

class ProNotifier extends Notifier<ProState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  @override
  ProState build() {
    final prefs = ref.read(sharedPreferencesProvider);

    ref.onDispose(() => _sub?.cancel());
    _init();
    return ProState(
      isPro: prefs.getBool(PrefsKeys.proPurchased) ?? false,
      isLegacy: prefs.getBool(PrefsKeys.legacyUser) ?? false,
    );
  }

  Future<void> _init() async {
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return;
      _sub = iap.purchaseStream.listen(_onPurchases,
          onError: (Object e) => debugPrint('Purchase stream error: $e'));
      final res = await iap.queryProductDetails({proProductId});
      if (res.productDetails.isNotEmpty) {
        _product = res.productDetails.first;
        state = state.copyWith(price: _product!.price);
      }
    } catch (e) {
      debugPrint('Pro init error: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != proProductId) continue;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _grant();
      }
      if (p.status == PurchaseStatus.error ||
          p.status == PurchaseStatus.canceled) {
        state = state.copyWith(busy: false);
      }
      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
  }

  Future<void> _grant() async {
    await ref.read(sharedPreferencesProvider).setBool(PrefsKeys.proPurchased, true);
    state = state.copyWith(isPro: true, busy: false);
  }

  /// 購入する。商品が取得できていなければ false
  Future<bool> buy() async {
    final product = _product;
    if (product == null) return false;
    state = state.copyWith(busy: true);
    try {
      return await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      debugPrint('Pro buy error: $e');
      state = state.copyWith(busy: false);
      return false;
    }
  }

  /// 購入を復元する（機種変更・入れ直し・ファミリー共有）
  Future<void> restore() async {
    state = state.copyWith(busy: true);
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('Pro restore error: $e');
    } finally {
      // 復元するものが無いときは通知が来ないので、少し待って処理中を解く
      Future.delayed(const Duration(seconds: 4), () {
        if (state.busy) state = state.copyWith(busy: false);
      });
    }
  }
}
