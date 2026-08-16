import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/local_storage.dart';

class SocketService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic> data)? onMessageReceived;
  bool isConnected = false;

  Future<void> connect(String sessionId, {required Function(Map<String, dynamic>) onMessage}) async {
    onMessageReceived = onMessage;
    final token = await LocalStorage.getAccessToken();
    if (token == null) return;

    final wsUri = Uri.parse("${ApiConstants.wsBaseUrl}/ws/tracking/$sessionId?token=$token");
    try {
      _channel = WebSocketChannel.connect(wsUri);
      isConnected = true;

      _channel?.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          onMessageReceived?.call(data);
        } catch (_) {}
      }, onDone: () {
        isConnected = false;
      }, onError: (_) {
        isConnected = false;
      });
    } catch (_) {
      isConnected = false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    isConnected = false;
  }
}
