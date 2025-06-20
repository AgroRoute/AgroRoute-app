import 'dart:convert';
import 'package:flutter_agroroute/constants/constants.dart';
import 'package:flutter_agroroute/helpers/helpers.dart';
import 'package:http/http.dart' as http;

class BaseService {
  final String baseUrl = Constants.baseUrl;
  final String path;
  final bool authenticated;

  BaseService({required this.path, required this.authenticated});

  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final url = Uri.parse('$baseUrl$path$endpoint')
        .replace(queryParameters: queryParams);
    final headers = await _createHeaders();

    final response = await http.get(url, headers: headers);
    return response;
  }

  Future<dynamic> post(String endpoint, [dynamic body]) async {
    final url = Uri.parse('$baseUrl$path$endpoint');
    final headers = await _createHeaders();

    final response = body != null
        ? await http.post(url, headers: headers, body: jsonEncode(body))
        : await http.post(url, headers: headers);

    //return _handleResponse(response);
    return response;
  }

  Future<dynamic> put(String endpoint,
      {dynamic body, Map<String, String>? queryParams}) async {
    final url = Uri.parse('$baseUrl$path$endpoint')
        .replace(queryParameters: queryParams);
    final headers = await _createHeaders();

    final response = body != null
        ? await http.put(url, headers: headers, body: jsonEncode(body))
        : await http.put(url, headers: headers);

    return response;
    //return _handleResponse(response);
  }

  Future<Map<String, String>> _createHeaders() async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};

    if (authenticated) {
      String token = await SecureStorageHelper().jwtToken;
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 402) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error: ${response.statusCode}, ${response.body}');
    }
  }
}