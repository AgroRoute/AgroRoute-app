import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/package.dart';
import 'package:flutter_agroroute/widgets/agroroute_scaffold.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PackagesDetailScreen extends StatelessWidget {
  final Package package;
  const PackagesDetailScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final fecha = package.fecha;
    return AgroRouteScaffold(
      selectedIndex: 2, // igual que en PackageDetailScreen de lib
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paquete ${package.codigo}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text("Fecha de envío"),
                subtitle: Text(fecha.toLocal().toString().split(' ')[0]),
              ),
            ),
            const SizedBox(height: 8),
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.description,
                      color: Colors.orange,
                    ),
                    title: const Text("Descripción"),
                    subtitle: Text(package.descripcion),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.monitor_weight,
                      color: Colors.brown,
                    ),
                    title: const Text("Peso"),
                    subtitle: Text("${package.peso} kg"),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.height, color: Colors.blueGrey),
                    title: const Text("Alto"),
                    subtitle: Text("${package.alto} cm"),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.straighten,
                      color: Colors.blueGrey,
                    ),
                    title: const Text("Ancho"),
                    subtitle: Text("${package.ancho} cm"),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.straighten,
                      color: Colors.blueGrey,
                    ),
                    title: const Text("Largo"),
                    subtitle: Text("${package.largo} cm"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sensores',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (package.sensores.isNotEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: package.sensores
                      .map(
                        (sensor) => ListTile(
                          leading: const Icon(
                            Icons.sensors,
                            color: Colors.deepPurple,
                          ),
                          title: Text(sensor.tipo),
                          subtitle: Text(sensor.valor.toString()),
                        ),
                      )
                      .toList(),
                ),
              )
            else
              const Text("No hay sensores registrados."),
          ],
        ),
      ),
    );
  }
}
