import 'package:flutter/material.dart';
import '../core/models/wedding.dart';
import '../core/models/wishlist_item.dart';
import '../core/models/contribution.dart';
import '../core/network/api_service.dart';

class WeddingProvider extends ChangeNotifier {
  bool _isLoading = false;
  Wedding? _wedding;
  List<WishlistItem> _wishlistItems = [];
  List<Contribution> _contributions = [];
  Map<String, dynamic>? _shareDetails;
  Map<String, dynamic>? _payoutInfo;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Wedding? get wedding => _wedding;
  List<WishlistItem> get wishlistItems => _wishlistItems;
  List<Contribution> get contributions => _contributions;
  Map<String, dynamic>? get shareDetails => _shareDetails;
  Map<String, dynamic>? get payoutInfo => _payoutInfo;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyWedding() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.getMyWedding();
      _isLoading = false;

      if (res['success'] == true) {
        _wedding = Wedding.fromJson(res['wedding']);
        _wishlistItems = (res['items'] as List)
            .map((item) => WishlistItem.fromJson(item))
            .toList();
        _contributions = (res['contributions'] as List)
            .map((c) => Contribution.fromJson(c))
            .toList();
        notifyListeners();
      } else {
        _errorMessage = res['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not load your wedding details';
      notifyListeners();
    }
  }

  Future<bool> createWedding({
    required String partner1Name,
    required String partner2Name,
    required String slug,
    required DateTime date,
    required String city,
    String? story,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.createWedding({
        'partner1Name': partner1Name,
        'partner2Name': partner2Name,
        'slug': slug,
        'date': date.toIso8601String(),
        'city': city,
        'story': story ?? '',
      });

      _isLoading = false;

      if (res['success'] == true) {
        _wedding = Wedding.fromJson(res['wedding']);
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Network error while creating wedding';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addWishlistItem({
    required String title,
    required String description,
    required String icon,
    required int targetAmount,
    int priority = 1,
  }) async {
    try {
      final res = await ApiService.createWishlistItem({
        'title': title,
        'description': description,
        'icon': icon,
        'targetAmount': targetAmount,
        'priority': priority,
      });

      if (res['success'] == true) {
        await fetchMyWedding();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateWishlistItem(String id, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.updateWishlistItem(id, data);
      if (res['success'] == true) {
        await fetchMyWedding();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWishlistItem(String id) async {
    try {
      final res = await ApiService.deleteWishlistItem(id);
      if (res['success'] == true) {
        await fetchMyWedding();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchShareDetails(String slug) async {
    try {
      final res = await ApiService.getShareDetails(slug);
      if (res['success'] == true) {
        _shareDetails = res;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching share details: $e');
    }
  }

  Future<void> fetchPayouts() async {
    try {
      final res = await ApiService.getPayouts();
      if (res['success'] == true) {
        _payoutInfo = res;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching payouts: $e');
    }
  }

  Future<bool> saveBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    String? upiId,
  }) async {
    try {
      final res = await ApiService.saveBankDetails({
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'upiId': upiId,
      });
      if (res['success'] == true) {
        await fetchPayouts();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestPayout(int amount, {String? notes}) async {
    try {
      final res = await ApiService.requestPayout(amount, notes: notes);
      if (res['success'] == true) {
        await fetchPayouts();
        await fetchMyWedding();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
