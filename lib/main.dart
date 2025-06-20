import 'package:flutter/material.dart';
import 'package:flutter_agroroute/components/alerts/alerts_screen.dart';
import 'package:flutter_agroroute/components/dashboard/dashboard_screen.dart';
import 'package:flutter_agroroute/components/packages/packages_screen.dart';
import 'package:flutter_agroroute/components/sensors/sensors_screen.dart';
import 'package:flutter_agroroute/components/shipments/shipments_screen.dart';
import 'package:flutter_agroroute/components/auth/login_screen.dart';
import 'package:flutter_agroroute/components/auth/register_screen.dart';
import 'home_screen.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  runApp(const AgroRouteApp());
}

class AgroRouteApp extends StatelessWidget {
  const AgroRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'AgroRoute',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeModeNotifier.value,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const SignUpScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/alerts': (context) =>
                const AlertsScreen(), // Placeholder for alerts
            '/shipments': (context) => ShipmentsScreen(),
            '/packages': (context) => const PackagesScreen(),
            '/sensors': (context) => const SensorsScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
