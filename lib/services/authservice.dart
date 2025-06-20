import 'package:flutter_agroroute/helpers/helpers.dart';
import 'package:flutter_agroroute/models/authenticated_user.dart';
import 'package:flutter_agroroute/models/login_request.dart';
import 'package:flutter_agroroute/models/register_request.dart';
import 'package:flutter_agroroute/services/BaseService.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService extends BaseService {
  AuthService() : super(authenticated: false, path: '/auth');

  Future<String> register(SignUpRequest req) async {
    final response = await post('/register', req.toJson());
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to register');
    }
  }

  Future<dynamic> login(SignInRequest req) async {
    try {
      final response = await post('/sign-in', req.toJson());
      print('Login response: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      SecureStorageHelper().setJwtToken(responseData['token']);
      print('Token: ${responseData['token']}');
      return responseData;
    } catch (e) {
      print("Error en login: $e");
      return 'USER_EMAIL_NOT_FOUND';
    }
  }

  Future<AuthenticatedUserDto?> decodeJwt(String token) async {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    final username = decodedToken['username']?.toString() ?? '';
    final userId = decodedToken['userId']?.toString() ?? '';
    final email = decodedToken['sub']?.toString() ?? '';

    SecureStorageHelper().setJwtToken(token);
    SecureStorageHelper().setUsername(username);
    SecureStorageHelper().setUserId(userId);

    print('TOKEN: $token');
    print('Username: $username');
    print('User ID: $userId');
    print('Email: $email');

    if (userId.isEmpty) {
      print('Error: userId no encontrado en el token');
      return null;
    }

    return AuthenticatedUserDto(id: userId, email: email, token: token);
  }

  Future<void> logout() async {
    await SecureStorageHelper().clear();
    print('Usuario desconectado y datos borrados');
  }
}
