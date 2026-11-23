import 'package:flutter/material.dart';
import '../core/models/wedding.dart';
import '../core/models/wishlist_item.dart';
import '../core/models/contribution.dart';
import '../core/network/api_service.dart';
import '../core/network/socket_service.dart';

class GuestProvider extends ChangeNotifier {
  bool _isLoading = true;
  Wedding? _wedding;
  List<WishlistItem> _items = [];
  List<Contribution> _recentContributions = [];
  String? _errorMessage;

  // Selected item for contribution
  WishlistItem? _selectedItem;
  int _selectedAmount = 2000; // Default quick chip
  bool _isCustomAmount = false;
  String _guestName = '';
  String _guestMessage = '';
  bool _isAnonymous = false;

  // Confirmed payment result for celebration
  Map<String, dynamic>? _lastContributionReceipt;

  bool get isLoading => _isLoading;
  Wedding? get wedding => _wedding;
  List<WishlistItem> get items => _items;
  List<Contribution> get recentContributions => _recentContributions;
  String? get errorMessage => _errorMessage;

  WishlistItem? get selectedItem => _selectedItem;
  int get selectedAmount => _selectedAmount;
  bool get isCustomAmount => _isCustomAmount;
  String get guestName => _guestName;
  String get guestMessage => _guestMessage;
  bool get isAnonymous => _isAnonymous;
  Map<String, dynamic>? get lastContributionReceipt => _lastContributionReceipt;

  Future<void> loadWedding(String slug) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.getPublicWedding(slug);
      _isLoading = false;

      if (res['success'] == true) {
        _wedding = Wedding.fromJson(res['wedding']);
        _items = (res['items'] as List)
            .map((item) => WishlistItem.fromJson(item))
            .toList();
        _recentContributions = (res['recentContributions'] as List)
            .map((c) => Contribution.fromJson(c))
            .toList();

        // Connect real-time socket
        _initSocket(_wedding!.id);

        notifyListeners();
      } else {
        _errorMessage = res['message'] ?? 'Wedding not found';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not load wedding wishlist. Check your connection.';
      notifyListeners();
    }
  }

  void _initSocket(String weddingId) {
    SocketService.initAndJoinWedding(
      weddingId,
      onNewContribution: (data) {
        debugPrint('[GuestProvider] Real-time contribution received!');
        // Update wedding total raised and count
        if (_wedding != null) {
          _wedding = Wedding(
            id: _wedding!.id,
            slug: _wedding!.slug,
            partner1Name: _wedding!.partner1Name,
            partner2Name: _wedding!.partner2Name,
            date: _wedding!.date,
            city: _wedding!.city,
            coverImageUrl: _wedding!.coverImageUrl,
            story: _wedding!.story,
            totalTarget: _wedding!.totalTarget,
            totalRaised: (data['weddingTotalRaised'] ?? _wedding!.totalRaised) as int,
            contributorCount: (data['contributorCount'] ?? _wedding!.contributorCount) as int,
            showAmounts: _wedding!.showAmounts,
          );

          // Update item if contributed to item
          final itemId = data['itemId'];
          if (itemId != null) {
            final index = _items.indexWhere((i) => i.id == itemId);
            if (index != -1) {
              final old = _items[index];
              final newRaised = (data['itemRaisedAmount'] ?? old.raisedAmount) as int;
              _items[index] = WishlistItem(
                id: old.id,
                weddingId: old.weddingId,
                title: old.title,
                description: old.description,
                icon: old.icon,
                targetAmount: old.targetAmount,
                raisedAmount: newRaised,
                contributorCount: old.contributorCount + 1,
                priority: old.priority,
                status: newRaised >= old.targetAmount ? 'funded' : old.status,
                percentFunded: (data['itemPercentFunded'] ?? old.percentFunded) as int,
                isFullyFunded: newRaised >= old.targetAmount,
              );
            }
          }

          // Prepend to recent contributions
          _recentContributions.insert(
            0,
            Contribution(
              id: data['contributionId'] ?? '',
              weddingId: _wedding!.id,
              itemId: data['itemId'],
              guestName: data['guestName'] ?? 'Generous Friend',
              amount: data['amount'],
              message: data['message'],
              createdAt: DateTime.now(),
            ),
          );

          notifyListeners();
        }
      },
      onWishlistUpdated: (itemsData) {
        _items = itemsData.map((item) => WishlistItem.fromJson(item)).toList();
        notifyListeners();
      },
    );
  }

  void selectItem(WishlistItem? item) {
    _selectedItem = item;
    notifyListeners();
  }

  void setAmount(int amount, {bool isCustom = false}) {
    _selectedAmount = amount;
    _isCustomAmount = isCustom;
    notifyListeners();
  }

  void setGuestDetails({
    required String name,
    String? message,
    bool isAnonymous = false,
  }) {
    _guestName = name;
    _guestMessage = message ?? '';
    _isAnonymous = isAnonymous;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> processContribution() async {
    if (_wedding == null || _selectedAmount < 10 || _guestName.trim().isEmpty) {
      return null;
    }

    try {
      // 1. Create order on server
      final orderRes = await ApiService.createOrder(
        weddingId: _wedding!.id,
        itemId: _selectedItem?.id,
        amount: _selectedAmount,
        guestName: _guestName.trim(),
        message: _guestMessage.trim(),
        isAnonymous: _isAnonymous,
      );

      if (orderRes['success'] != true) {
        throw Exception(orderRes['message'] ?? 'Failed to create payment order');
      }

      final orderData = orderRes['order'];
      final orderId = orderData['orderId'];

      // 2. Mock payment / standard verification
      final paymentId = 'pay_sim_${DateTime.now().millisecondsSinceEpoch}';
      final signature = 'simulated_valid_sig_$orderId';

      final verifyRes = await ApiService.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );

      if (verifyRes['success'] == true) {
        _lastContributionReceipt = {
          'receiptNumber': verifyRes['contribution']['receiptNumber'] ?? 'DW-REC-2026',
          'amount': _selectedAmount,
          'itemTitle': _selectedItem?.title ?? 'General Wedding Fund',
          'coupleNames': _wedding!.coupleTitle,
          'guestName': _guestName,
          'message': _guestMessage,
          'date': DateTime.now().toIso8601String(),
        };

        notifyListeners();
        return _lastContributionReceipt;
      }
      return null;
    } catch (e) {
      debugPrint('[Payment] Error processing contribution: $e');
      return null;
    }
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }
}
