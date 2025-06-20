import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/shipment.dart';
import 'package:flutter_agroroute/models/sensor.dart';
import 'package:flutter_agroroute/models/package.dart';
import 'package:flutter_agroroute/helpers/helpers.dart';
import 'package:flutter_agroroute/widgets/agroroute_scaffold.dart';
import 'package:flutter_agroroute/components/sensors/sensors_detail_screen.dart';
import 'package:http/http.dart' as http;

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  List<Map<String, dynamic>> _sensorPackageList = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSensors();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSensors() async {
    setState(() => _loading = true);
    try {
      final userId = await SecureStorageHelper().userId;
      final response = await http.get(
        Uri.parse(
          'https://server-production-e741.up.railway.app/api/v1/shipments',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final shipments = data
            .map((e) => Shipment.fromJson(e))
            .where(
              (s) =>
                  s.ownerId == userId &&
                  (s.estado.toLowerCase() == "en proceso" ||
                      s.estado.toLowerCase() == "listo"),
            )
            .toList();

        final List<Map<String, dynamic>> sensorPackageList = [];
        for (final shipment in shipments) {
          for (final pkg in shipment.paquetes) {
            for (final sensor in pkg.sensores) {
              sensorPackageList.add({'sensor': sensor, 'package': pkg});
            }
          }
        }
        setState(() {
          _sensorPackageList = sensorPackageList;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar sensores: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredSensorPackageList {
    if (_searchQuery.isEmpty) return _sensorPackageList;
    return _sensorPackageList.where((item) {
      final sensor = item['sensor'] as Sensor;
      final pkg = item['package'] as Package;
      return sensor.tipo.toLowerCase().contains(_searchQuery) ||
          sensor.valor.toString().contains(_searchQuery) ||
          pkg.codigo.toLowerCase().contains(_searchQuery) ||
          pkg.cliente.toLowerCase().contains(_searchQuery) ||
          pkg.destino.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredList = _filteredSensorPackageList;

    return AgroRouteScaffold(
      selectedIndex: 4,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 90.0,
              floating: true,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Mis Sensores',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeaderDelegate(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar sensores...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : filteredList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sensors, size: 60, color: theme.disabledColor),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No tienes sensores registrados'
                          : 'No se encontraron resultados',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchSensors,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final sensor = filteredList[index]['sensor'] as Sensor;
                    final pkg = filteredList[index]['package'] as Package;
                    return _SensorCard(
                      sensor: sensor,
                      package: pkg,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SensorsDetailScreen(
                              sensor: sensor,
                              package: pkg,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final Sensor sensor;
  final Package package;
  final VoidCallback onTap;

  const _SensorCard({
    required this.sensor,
    required this.package,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sensor.tipo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sensor.activo
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sensor.activo
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      sensor.activo ? "ACTIVO" : "INACTIVO",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: sensor.activo ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SensorInfoRow(
                icon: Icons.data_usage,
                label: 'Valor',
                value: sensor.valor.toString(),
              ),
              const SizedBox(height: 8),
              _SensorInfoRow(
                icon: Icons.inventory_2,
                label: 'Paquete',
                value: package.codigo,
              ),
              const SizedBox(height: 8),
              _SensorInfoRow(
                icon: Icons.person_outline,
                label: 'Cliente',
                value: package.cliente,
              ),
              const SizedBox(height: 8),
              _SensorInfoRow(
                icon: Icons.place,
                label: 'Destino',
                value: package.destino,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    Icons.monitor_heart,
                    size: 18,
                    color: const Color(0xFF2D4F2B),
                  ),
                  label: Text(
                    'MONITOREAR',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2D4F2B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSensorColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'temperatura':
        return Colors.deepOrange;
      case 'humedad':
        return Colors.blue;
      case 'ubicación':
      case 'ubicacion':
        return Colors.green;
      default:
        return Colors.deepPurple;
    }
  }
}

class _SensorInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SensorInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(text: value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: shrinkOffset > 0 ? 2 : 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
