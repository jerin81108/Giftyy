import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

class SocketService {
  static io.Socket? _socket;
  static String? _currentWeddingId;

  static void initAndJoinWedding(
    String weddingId, {
    required Function(Map<String, dynamic> data) onNewContribution,
    required Function(List<dynamic> items) onWishlistUpdated,
  }) {
    if (_socket != null && _currentWeddingId == weddingId) {
      return;
    }

    disconnect();
    _currentWeddingId = weddingId;

    final socketUrl = ApiService.baseUrl.replaceAll('/api', '');

    try {
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('[Socket] Connected to server, joining wedding: $weddingId');
        _socket!.emit('join_wedding', weddingId);
      });

      _socket!.on('new_contribution', (data) {
        debugPrint('[Socket] Received new contribution: $data');
        if (data is Map<String, dynamic>) {
          onNewContribution(data);
        }
      });

      _socket!.on('wishlist_updated', (items) {
        debugPrint('[Socket] Wishlist updated');
        if (items is List) {
          onWishlistUpdated(items);
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('[Socket] Disconnected from real-time server');
      });
    } catch (e) {
      debugPrint('[Socket] Connection error: $e');
    }
  }

  static void disconnect() {
    if (_socket != null) {
      if (_currentWeddingId != null) {
        _socket!.emit('leave_wedding', _currentWeddingId);
      }
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _currentWeddingId = null;
    }
  }
}
