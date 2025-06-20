import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/sensor.dart';
import 'package:flutter_agroroute/models/package.dart';
import 'package:flutter_agroroute/widgets/agroroute_scaffold.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SensorsDetailScreen extends StatefulWidget {
  final Sensor sensor;
  final Package package;
  const SensorsDetailScreen({
    super.key,
    required this.sensor,
    required this.package,
  });

  @override
  State<SensorsDetailScreen> createState() => _SensorsDetailScreenState();
}

class _SensorsDetailScreenState extends State<SensorsDetailScreen> {
  late bool _activo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _activo = widget.sensor.activo;
  }

  Future<void> _toggleActivo() async {
    setState(() => _loading = true);

    final sensorIndex = widget.package.sensores.indexWhere(
      (s) => s.tipo == widget.sensor.tipo && s.valor == widget.sensor.valor,
    );

    if (sensorIndex == -1) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el sensor en el paquete')),
      );
      return;
    }

    final shipmentId = widget.package.shipmentId?.toString() ?? '';
    final packageCode = widget.package.codigo;
    final url =
        'https://server-production-e741.up.railway.app/api/v1/shipments/$shipmentId/packages/$packageCode/sensors/$sensorIndex';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'activo': !_activo}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _activo = !_activo;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_activo ? 'Sensor activado' : 'Sensor desactivado'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de red: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensor = widget.sensor;
    final package = widget.package;
    return AgroRouteScaffold(
      selectedIndex: 4,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.sensors,
                    color: Colors.deepPurple,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sensor: ${sensor.tipo}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: Colors.teal,
                    ),
                    title: const Text("Cliente"),
                    subtitle: Text(package.cliente),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.sensors,
                      color: Colors.deepPurple,
                    ),
                    title: const Text("Tipo de sensor"),
                    subtitle: Text(sensor.tipo),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.data_usage, color: Colors.blue),
                    title: const Text("Valor"),
                    subtitle: Text(sensor.valor.toString()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.teal,
                    ),
                    title: const Text("Fecha de destino"),
                    subtitle: Text(
                      package.fecha.toLocal().toString().split(' ')[0],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      _activo ? Icons.check_circle : Icons.cancel,
                      color: _activo ? Colors.green : Colors.red,
                    ),
                    title: const Text("¿Activo?"),
                    subtitle: Text(_activo ? "Sí" : "No"),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      package.estado.toLowerCase() == "listo"
                          ? Icons.check_circle
                          : Icons.timelapse,
                      color: package.estado.toLowerCase() == "listo"
                          ? Colors.green
                          : Colors.orange,
                    ),
                    title: const Text("Estado del paquete"),
                    subtitle: Text(package.estado),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                    ),
                    title: const Text("Destino"),
                    subtitle: Text(package.destino),
                  ),
                  if (package.destinoLat != null && package.destinoLng != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        height: 180,
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  package.destinoLat!,
                                  package.destinoLng!,
                                ),
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('destinoPaquete'),
                                  position: LatLng(
                                    package.destinoLat!,
                                    package.destinoLng!,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: package.destino,
                                  ),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              liteModeEnabled: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.monitor_heart, color: Colors.red),
                  label: const Text(
                    'Monitorear',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Monitoreo iniciado para este sensor',
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: Icon(
                    _activo ? Icons.toggle_off : Icons.toggle_on,
                    color: _activo ? Colors.red : Colors.green,
                  ),
                  label: Text(
                    _activo ? 'Desactivar' : 'Activar',
                    style: TextStyle(
                      color: _activo ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _activo ? Colors.red : Colors.green,
                    ),
                    foregroundColor: _activo ? Colors.red : Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _loading ? null : _toggleActivo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
