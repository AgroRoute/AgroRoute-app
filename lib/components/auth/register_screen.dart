import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/register_request.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  bool _validateFields() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _dniController.text.isEmpty ||
        _birthDateController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Todos los campos son obligatorios');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showSnackBar('Correo inválido');
      return false;
    }
    try {
      DateTime.parse(_birthDateController.text);
    } catch (_) {
      _showSnackBar('Fecha de nacimiento inválida (formato: yyyy-MM-dd)');
      return false;
    }
    return true;
  }

  Future<void> _registerUser() async {
    if (!_validateFields()) return;

    try {
      final req = SignUpRequest(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dni: _dniController.text,
        birthDate: DateTime.parse(_birthDateController.text),
        phoneNumber: _phoneNumberController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      final response = await http.post(
        Uri.parse(
          'https://server-production-e741.up.railway.app/api/v1/auth/sign-up',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (response.statusCode == 201) {
        _showSnackBar('Registro exitoso', color: Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        final data = jsonDecode(response.body);
        String errorMsg = 'Registro no exitoso';
        if (data['message']?.contains('Usuario ya existe') ?? false) {
          errorMsg = 'Correo ya utilizado por otro usuario';
        }
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      _showSnackBar('Error de red: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF708A58);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Image.network(
                        'https://i.postimg.cc/xCY7LjjP/image-removebg-preview-1.png',
                        height: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Crea tu cuenta",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Completa tus datos para continuar",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _ModernTextField(
                  controller: _firstNameController,
                  label: 'Nombres',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _ModernTextField(
                  controller: _lastNameController,
                  label: 'Apellidos',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _ModernTextField(
                  controller: _dniController,
                  label: 'DNI',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _ModernTextField(
                  controller: _birthDateController,
                  label: 'Fecha de nacimiento (yyyy-MM-dd)',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 12),
                _ModernTextField(
                  controller: _phoneNumberController,
                  label: 'Teléfono',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _ModernTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _ModernTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _registerUser,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Registrarse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes una cuenta?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF708A58);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
        ),
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.04)
            : primaryColor.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: primaryColor.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }
}
