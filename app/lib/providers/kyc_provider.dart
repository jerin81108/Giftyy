import 'package:flutter/material.dart';
import '../core/network/api_service.dart';

class KycProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _status = 'not_started';
  String? _maskedPan;
  String? _panLast4;
  String? _aadhaarLast4;
  String? _verifiedName;
  String? _rejectionReason;
  String? _consentVersion;
  DateTime? _consentAt;
  bool _isPublicAllowed = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String get status => _status;
  bool get isVerified => _status == 'verified';
  bool get isPending => _status == 'pending';
  bool get isRejected => _status == 'rejected';
  bool get hasConsent => _consentAt != null;
  String? get maskedPan => _maskedPan;
  String? get panLast4 => _panLast4;
  String? get aadhaarLast4 => _aadhaarLast4;
  String? get verifiedName => _verifiedName;
  String? get rejectionReason => _rejectionReason;
  String? get consentVersion => _consentVersion;
  bool get isPublicAllowed => _isPublicAllowed;
  String? get errorMessage => _errorMessage;

  Future<void> fetchKycStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.getKycStatus();
      _isLoading = false;

      if (res['success'] == true) {
        final kyc = res['kyc'];
        _status = kyc['status'] ?? 'not_started';
        _maskedPan = kyc['maskedPan'];
        _panLast4 = kyc['panLast4'];
        _aadhaarLast4 = kyc['aadhaarLast4'];
        _verifiedName = kyc['verifiedName'];
        _rejectionReason = kyc['rejectionReason'];
        _consentVersion = kyc['consentVersion'];
        _isPublicAllowed = kyc['isPublicAllowed'] ?? false;
        if (kyc['consentAt'] != null) {
          _consentAt = DateTime.parse(kyc['consentAt']);
        }
        notifyListeners();
      } else {
        _errorMessage = res['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not fetch KYC status';
      notifyListeners();
    }
  }

  Future<bool> acceptConsent(String version) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.submitConsent(version);
      _isLoading = false;

      if (res['success'] == true) {
        _consentVersion = version;
        _consentAt = DateTime.now();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      return false;
    }
  }

  Future<bool> verifyPan({
    required String panNumber,
    required String fullName,
    String? dob,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.verifyPan(
        panNumber: panNumber,
        fullName: fullName,
        dob: dob,
      );
      _isLoading = false;

      if (res['success'] == true) {
        _status = res['status'];
        _maskedPan = res['maskedPan'];
        _verifiedName = res['verifiedName'];
        _isPublicAllowed = true;
        notifyListeners();
        return true;
      } else {
        _status = res['status'] ?? 'rejected';
        _errorMessage = res['message'] ?? 'PAN verification failed';
        _rejectionReason = _errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyAadhaar({
    required String aadhaarNumber,
    String? otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.verifyAadhaar(
        aadhaarNumber: aadhaarNumber,
        otp: otp,
      );
      _isLoading = false;

      if (res['success'] == true) {
        _aadhaarLast4 = aadhaarNumber.slice(-4);
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Aadhaar verification failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyLiveness() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.verifyLiveness();
      _isLoading = false;
      return res['success'] == true;
    } catch (e) {
      _isLoading = false;
      return false;
    }
  }
}

extension StringSlice on String {
  String slice(int start) {
    if (length < 4) return this;
    return substring(length + start);
  }
}
