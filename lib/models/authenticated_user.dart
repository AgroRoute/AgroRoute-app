class AuthenticatedUserDto  {
  final String id;
  final String email;
  final String token;

  const AuthenticatedUserDto({
    required this.id,
    required this.email,
    required this.token,
  });

  factory AuthenticatedUserDto.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'token': token,
    };
  }
}
