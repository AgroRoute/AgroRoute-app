import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_agroroute/models/shipment.dart';
import 'package:flutter_agroroute/widgets/agroroute_scaffold.dart';

class ShipmentsDetailScreen extends StatelessWidget {
  final Shipment shipment;
  const ShipmentsDetailScreen({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return AgroRouteScaffold(
      selectedIndex: 1,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.blueAccent,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Detalle del Envío',
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
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.teal),
                title: const Text("Fecha de envío"),
                subtitle: Text(
                  shipment.fecha.toLocal().toString().split(' ')[0],
                ),
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
                      Icons.confirmation_number,
                      color: Colors.indigo,
                    ),
                    title: const Text("ID de Tracking"),
                    subtitle: Text(
                      shipment.trackingNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.teal),
                    title: const Text("Destino"),
                    subtitle: Text(shipment.destino),
                  ),
                  if (shipment.destinoLat != null &&
                      shipment.destinoLng != null)
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
                                  shipment.destinoLat!,
                                  shipment.destinoLng!,
                                ),
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('destinoEnvio'),
                                  position: LatLng(
                                    shipment.destinoLat!,
                                    shipment.destinoLng!,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: shipment.destino,
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
                    leading: const Icon(Icons.info, color: Colors.orange),
                    title: const Text("Estado"),
                    subtitle: Text(shipment.estado),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gps_fixed, color: Colors.green),
                    title: const Text("Ubicación activada"),
                    subtitle: Text(shipment.ubicacion ? 'Sí' : 'No'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Paquetes",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (shipment.paquetes.isNotEmpty)
              Column(
                children: shipment.paquetes.map((p) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p.codigo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Chip(
                                label: Text(p.estado),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _PaqueteInfoRow(label: "Cliente", value: p.cliente),
                          _PaqueteInfoRow(label: "Destino", value: p.destino),
                          _PaqueteInfoRow(
                            label: "Fecha",
                            value: p.fecha.toLocal().toString().split(' ')[0],
                          ),
                          // Puedes agregar más campos si lo deseas
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              const Text('No hay paquetes registrados'),
          ],
        ),
      ),
    );
  }
}

class _PaqueteInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _PaqueteInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
