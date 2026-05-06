import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket? _socket;

  // Track registered handlers to avoid duplicates
  final Map<String, List<dynamic Function(dynamic)>> _handlers = {};

  // Connect to the socket server
  void connect(String token, String userId, String role) {
    if (_socket != null && _socket!.connected) return;

    // Use full base URL but without /api
    String url = ApiConfig.baseUrl.replaceAll('/api', '');

    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');

      // Join the specific room based on role
      if (role.toUpperCase() == 'STUDENT') {
        _socket!.emit('join_student_room', userId);
      } else {
        _socket!.emit('join_teacher_room', userId);
      }

      // Re-register all stored handlers after reconnect
      _handlers.forEach((event, handlerList) {
        for (final handler in handlerList) {
          _socket!.on(event, handler);
        }
      });
    });

    _socket!.onDisconnect((_) => print('Socket disconnected'));
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _handlers.clear();
    }
  }

  /// Register an event handler. Always replaces any previous handler
  /// for the same event to prevent duplicate listeners from IndexedStack.
  void on(String event, dynamic Function(dynamic) handler) {
    _socket?.off(event);
    _handlers[event] = [handler];
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
    _handlers.remove(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  bool get isConnected => _socket?.connected ?? false;
}
