import 'package:flutter/material.dart';
import '../core/network/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _phone;
  String? _token;
  Map<String, dynamic>? _user;
  String? _weddingSlug;
  bool _hasWedding = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get phone => _phone;
  Map<String, dynamic>? get user => _user;
  String? get weddingSlug => _weddingSlug;
  bool get hasWedding => _hasWedding;
  String? get errorMessage => _errorMessage;

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.sendOtp(phone);
      _isLoading = false;
      if (res['success'] == true) {
        _phone = phone;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to send OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Network error: could not connect to server';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp, {String? name}) async {
    if (_phone == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.verifyOtp(_phone!, otp, name: name);
      _isLoading = false;

      if (res['success'] == true) {
        _token = res['token'];
        ApiService.authToken = _token;
        _user = res['user'];
        _hasWedding = res['hasWedding'] ?? false;
        _weddingSlug = res['weddingSlug'];
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Invalid OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Network error during verification';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _token = null;
    ApiService.authToken = null;
    _user = null;
    _hasWedding = false;
    _weddingSlug = null;
    notifyListeners();
  }
}
