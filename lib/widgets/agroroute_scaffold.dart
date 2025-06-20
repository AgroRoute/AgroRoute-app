import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class AgroRouteScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final int selectedIndex;
  final FloatingActionButton? floatingActionButton;

  AgroRouteScaffold({
    super.key,
    required this.body,
    this.title = 'AgroRoute',
    this.selectedIndex = 0,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final NotchBottomBarController _notchController = NotchBottomBarController(
      index: selectedIndex,
    );

    void _onItemTapped(BuildContext context, int index) {
      if (index == selectedIndex) return;
      _notchController.jumpTo(index);
      switch (index) {
        case 0:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
          break;
        case 1:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/shipments',
            (route) => false,
          );
          break;
        case 2:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/packages',
            (route) => false,
          );
          break;
        case 3:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/alerts',
            (route) => false,
          );
          break;
        case 4:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sensors',
            (route) => false,
          );
          break;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.background,
        title: Row(
          children: [
            Image.network(
              'https://i.postimg.cc/xCY7LjjP/image-removebg-preview-1.png',
              height: 40,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).iconTheme.color,
            ),
            tooltip: 'Cambiar modo día/noche',
            onPressed: () {
              themeModeNotifier.value =
                  Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              child: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.logout,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          ),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _notchController,
        color: Theme.of(context).colorScheme.surface,
        showLabel: true,
        notchColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF181C2A)
            : const Color(0xFF2D4F2B),
        itemLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        durationInMilliSeconds: 300,
        bottomBarWidth: MediaQuery.of(context).size.width,
        kIconSize: 24.0,
        kBottomRadius: 28.0,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(
              Icons.dashboard_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            activeItem: Icon(Icons.dashboard, color: Colors.white),
            itemLabel: 'Dashboard',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.local_shipping_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            activeItem: Icon(Icons.local_shipping, color: Colors.white),
            itemLabel: 'Envíos',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.inventory_2_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            activeItem: Icon(Icons.inventory_2, color: Colors.white),
            itemLabel: 'Paquetes',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.warning_amber_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            activeItem: Icon(Icons.warning_amber, color: Colors.white),
            itemLabel: 'Alertas',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.sensors_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            activeItem: Icon(Icons.sensors, color: Colors.white),
            itemLabel: 'Sensores',
          ),
        ],
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }
}
