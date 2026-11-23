import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for web/desktop/iOS simulator
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000/api'
        : 'http://localhost:5000/api';
  }

  static String? authToken;

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // --- Auth ---
  static Future<dynamic> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: _headers,
      body: jsonEncode({'phone': phone}),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> verifyOtp(
    String phone,
    String otp, {
    String? name,
    String? email,
    String? dob,
    String? partnerName,
    String? city,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _headers,
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (dob != null) 'dob': dob,
        if (partnerName != null) 'partnerName': partnerName,
        if (city != null) 'city': city,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // --- KYC & Identity Verification (DPDP Act Compliant) ---
  static Future<dynamic> getKycStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/kyc/status'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> submitConsent(String consentVersion) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kyc/consent'),
      headers: _headers,
      body: jsonEncode({
        'consentVersion': consentVersion,
        'acceptedTerms': true,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> verifyPan({
    required String panNumber,
    required String fullName,
    String? dob,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kyc/verify-pan'),
      headers: _headers,
      body: jsonEncode({
        'panNumber': panNumber,
        'fullName': fullName,
        if (dob != null) 'dob': dob,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> verifyAadhaar({
    required String aadhaarNumber,
    String? otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kyc/verify-aadhaar'),
      headers: _headers,
      body: jsonEncode({
        'aadhaarNumber': aadhaarNumber,
        if (otp != null) 'otp': otp,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> verifyLiveness() async {
    final response = await http.post(
      Uri.parse('$baseUrl/kyc/verify-liveness'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> deleteMyData() async {
    final response = await http.post(
      Uri.parse('$baseUrl/kyc/delete-my-data'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // --- Wedding (Couple & Public) ---
  static Future<dynamic> createWedding(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/weddings'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getMyWedding() async {
    final response = await http.get(
      Uri.parse('$baseUrl/weddings/me'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> updateWedding(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/weddings/me'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getPublicWedding(String slug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weddings/public/$slug'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getShareDetails(String slug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weddings/share/$slug'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> reportWedding({
    required String slug,
    required String reason,
    String? reporterName,
    String? details,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/weddings/report/$slug'),
      headers: _headers,
      body: jsonEncode({
        'reason': reason,
        if (reporterName != null) 'reporterName': reporterName,
        if (details != null) 'details': details,
      }),
    );
    return jsonDecode(response.body);
  }

  // --- Wishlist Items ---
  static Future<dynamic> getWishlistItems() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wishlist'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> createWishlistItem(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wishlist'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> updateWishlistItem(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/wishlist/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> deleteWishlistItem(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wishlist/$id'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // --- Payments ---
  static Future<dynamic> createOrder({
    required String weddingId,
    String? itemId,
    required int amount,
    required String guestName,
    String? guestPhone,
    String? guestEmail,
    String? message,
    bool isAnonymous = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-order'),
      headers: _headers,
      body: jsonEncode({
        'weddingId': weddingId,
        if (itemId != null) 'itemId': itemId,
        'amount': amount,
        'guestName': guestName,
        if (guestPhone != null) 'guestPhone': guestPhone,
        if (guestEmail != null) 'guestEmail': guestEmail,
        if (message != null) 'message': message,
        'isAnonymous': isAnonymous,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify'),
      headers: _headers,
      body: jsonEncode({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getReceipt(String contributionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/receipt/$contributionId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // --- Payouts ---
  static Future<dynamic> saveBankDetails(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payouts/bank-details'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> requestPayout(int amount, {String? notes, String? payoutOtp}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payouts/request'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        if (notes != null) 'notes': notes,
        if (payoutOtp != null) 'payoutOtp': payoutOtp,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getPayouts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/payouts'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // --- Event Rooms Platform ---
  static Future<dynamic> getRoomTemplates() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rooms/templates'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getWishlist(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rooms/$roomId/wishlist'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> createRoom(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getRoom(String slugOrCode, {String? guestId}) async {
    final uri = Uri.parse('$baseUrl/rooms/$slugOrCode').replace(
      queryParameters: guestId != null ? {'guestId': guestId} : null,
    );
    final headers = Map<String, String>.from(_headers);
    if (guestId != null) {
      headers['x-guest-id'] = guestId;
    }
    final response = await http.get(uri, headers: headers);
    return jsonDecode(response.body);
  }

  static Future<dynamic> joinRoom(
    String roomId, {
    required String displayName,
    String? phone,
    String? email,
    String? avatarUrl,
    String? guestId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/$roomId/join'),
      headers: _headers,
      body: jsonEncode({
        'displayName': displayName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (guestId != null) 'guestId': guestId,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getRoomMembers(String roomId, {String? guestId}) async {
    final headers = Map<String, String>.from(_headers);
    if (guestId != null) {
      headers['x-guest-id'] = guestId;
    }
    final response = await http.get(
      Uri.parse('$baseUrl/rooms/$roomId/members'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> updateMemberStatus(
    String roomId,
    String memberId, {
    String? status,
    String? role,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/rooms/$roomId/members/$memberId'),
      headers: _headers,
      body: jsonEncode({
        if (status != null) 'status': status,
        if (role != null) 'role': role,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> submitRoomRsvp(
    String roomId, {
    required String rsvpStatus,
    int guestCount = 1,
    String? displayName,
    String? guestId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/$roomId/rsvp'),
      headers: _headers,
      body: jsonEncode({
        'rsvpStatus': rsvpStatus,
        'guestCount': guestCount,
        if (displayName != null) 'displayName': displayName,
        if (guestId != null) 'guestId': guestId,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getRoomPosts(String roomId, {String? type}) async {
    final uri = Uri.parse('$baseUrl/rooms/$roomId/posts').replace(
      queryParameters: type != null ? {'type': type} : null,
    );
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  static Future<dynamic> createRoomPost(
    String roomId, {
    required String type,
    required String content,
    String? mediaUrl,
    String? authorName,
    String? memberId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/$roomId/posts'),
      headers: _headers,
      body: jsonEncode({
        'type': type,
        'content': content,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (authorName != null) 'authorName': authorName,
        if (memberId != null) 'memberId': memberId,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> regenerateRoomQr(String roomId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/$roomId/regenerate-qr'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> lockRoom(String roomId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/rooms/$roomId/lock'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> deleteRoom(String roomId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/rooms/$roomId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }
}
