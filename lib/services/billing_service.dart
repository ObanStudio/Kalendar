import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

const String kPlusProductId = 'kalendar_plus_lifetime';

class BillingService extends ChangeNotifier {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _isAvailable = false;
  bool _isPlusActiveCached = false;
  DateTime? _promoExpiry;
  bool _isLoading = false;
  String? _errorMessage;

  ProductDetails? _plusProduct;

  bool get isAvailable => _isAvailable;
  
  bool get isPlusActive {
    if (_isPlusActiveCached) return true;
    if (_promoExpiry != null && _promoExpiry!.isAfter(DateTime.now())) return true;
    return false;
  }

  bool get isPromoActive => _promoExpiry != null && _promoExpiry!.isAfter(DateTime.now());

  String get promoRemaining {
    if (_promoExpiry == null) return '';
    final diff = _promoExpiry!.difference(DateTime.now());
    if (diff.isNegative) return 'Срок истёк';
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);
    if (h > 0) return '${h}ч ${m}м ${s}с';
    return '${m}м ${s}с';
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProductDetails? get plusProduct => _plusProduct;

  Future<void> initialize() async {
    _isPlusActiveCached = await StorageService.loadIsPlusCached();
    final promoMs = await StorageService.loadPromoExpiry();
    if (promoMs > 0) {
      _promoExpiry = DateTime.fromMillisecondsSinceEpoch(promoMs);
    }
    notifyListeners();

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => _setError(e.toString()),
    );
    await _loadProducts();
    await _iap.restorePurchases();
  }

  Future<bool> applyPromoCode(String code) async {
    if (code.trim().toUpperCase() == 'TEST1HOUR') {
      _promoExpiry = DateTime.now().add(const Duration(hours: 1));
      await StorageService.savePromoExpiry(_promoExpiry!.millisecondsSinceEpoch);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({kPlusProductId});
    if (response.error != null) {
      _setError(response.error!.message);
      return;
    }
    if (response.productDetails.isNotEmpty) {
      _plusProduct = response.productDetails.first;
      notifyListeners();
    }
  }

  Future<void> buyPlus() async {
    if (_plusProduct == null) {
      _setError('Продукт недоступен. Проверьте соединение.');
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: _plusProduct!);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == kPlusProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _activatePlus();
        } else if (purchase.status == PurchaseStatus.error) {
          _setError(purchase.error?.message ?? 'Ошибка покупки');
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _activatePlus() async {
    _isPlusActiveCached = true;
    await StorageService.savePlusStatus(true);
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
