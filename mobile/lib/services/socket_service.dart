import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';

class SocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  Function(Map<String, dynamic> data)? onMessageReceived;
  Function(bool isConnected)? onConnectionChanged;

  bool isConnected = false;
  bool _shouldBeConnected = false;
  String? _currentSessionId;
  int _reconnectAttempts = 0;

  /// Connect to the real-time tracking session WebSocket.
  Future<void> connect(
    String sessionId, {
    required Function(Map<String, dynamic>) onMessage,
    Function(bool)? onStatusChange,
  }) async {
    _currentSessionId = sessionId;
    _shouldBeConnected = true;
    onMessageReceived = onMessage;
    if (onStatusChange != null) {
      onConnectionChanged = onStatusChange;
    }

    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (!_shouldBeConnected || _currentSessionId == null) return;

    final token = await LocalStorage.getAccessToken();
    if (token == null) {
      debugPrint("[SocketService] Cannot connect: missing access token.");
      return;
    }

    final wsEndpoint = "${ApiClient.wsBaseUrl}/ws/tracking/$_currentSessionId?token=$token";
    debugPrint("[SocketService] Connecting WebSocket to: $wsEndpoint (attempt: ${_reconnectAttempts + 1})");

    try {
      final wsUri = Uri.parse(wsEndpoint);
      _cleanupCurrentConnection();

      _channel = WebSocketChannel.connect(wsUri);
      
      _subscription = _channel?.stream.listen(
        (message) {
          if (!isConnected) {
            _setConnected(true);
          }
          try {
            if (message == '{"type": "pong"}' || message == 'pong') {
              // Heartbeat response acknowledged
              return;
            }
            final data = jsonDecode(message);
            onMessageReceived?.call(data);
          } catch (e) {
            debugPrint("[SocketService] Failed to parse message: $e");
          }
        },
        onDone: () {
          debugPrint("[SocketService] WebSocket connection closed by server.");
          _handleDisconnect();
        },
        onError: (err) {
          debugPrint("[SocketService] WebSocket stream error: $err");
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _setConnected(true);
      _startPingTimer();
    } catch (e) {
      debugPrint("[SocketService] Connection exception: $e");
      _handleDisconnect();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (isConnected && _channel != null) {
        try {
          _channel?.sink.add("ping");
        } catch (e) {
          debugPrint("[SocketService] Ping failed: $e");
        }
      }
    });
  }

  void _handleDisconnect() {
    _setConnected(false);
    _cleanupCurrentConnection();

    if (_shouldBeConnected && _currentSessionId != null) {
      _reconnectAttempts++;
      // Exponential backoff: 2s, 4s, 8s, capped at 16s
      final delaySeconds = (_reconnectAttempts <= 4) ? (1 << _reconnectAttempts) : 16;
      debugPrint("[SocketService] Reconnecting in $delaySeconds seconds...");
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
        if (_shouldBeConnected) {
          _establishConnection();
        }
      });
    }
  }

  void _setConnected(bool status) {
    if (isConnected != status) {
      isConnected = status;
      if (status) {
        _reconnectAttempts = 0;
      }
      onConnectionChanged?.call(status);
    }
  }

  void _cleanupCurrentConnection() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Disconnect explicitly and stop all reconnection attempts.
  void disconnect() {
    _shouldBeConnected = false;
    _currentSessionId = null;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _setConnected(false);
    _cleanupCurrentConnection();
    debugPrint("[SocketService] Disconnected cleanly.");
  }
}
