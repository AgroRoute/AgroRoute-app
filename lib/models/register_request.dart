class SignUpRequest {
  final String firstName;
  final String lastName;
  final String dni;
  final DateTime birthDate;
  final String phoneNumber;
  final String email;
  final String password;
  final List<String>? roles;

  SignUpRequest({
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.birthDate,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.roles,
  });

  factory SignUpRequest.fromJson(Map<String, dynamic> json) {
    return SignUpRequest(
      firstName: json['firstName'],
      lastName: json['lastName'],
      dni: json['dni'],
      birthDate: DateTime.parse(json['birthDate']),
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      password: json['password'],
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'dni': dni,
      'birthDate': birthDate.toIso8601String(),
      'phoneNumber': phoneNumber,
      'email': email,
      'password': password,
      if (roles != null) 'roles': roles,
    };
  }
}