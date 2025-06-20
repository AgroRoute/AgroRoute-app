import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/constants.dart';

class WebSocketService {
  late WebSocketChannel _channel;

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(Constants.baseUrlWebSocket));
  }

  Stream get stream => _channel.stream;

  void send(String message) {
    _channel.sink.add(message);
  }

  void disconnect() {
    _channel.sink.close();
  }
}
