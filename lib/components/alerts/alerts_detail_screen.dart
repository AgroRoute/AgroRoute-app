import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/alert.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlertsDetailScreen extends StatelessWidget {
  final AlertModel alert;
  const AlertsDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final destino = alert.sensor.destino ?? 'Desconocido';
    final cliente = alert.sensor.cliente ?? 'Desconocido';
    final paqueteId = alert.sensor.packageCode ?? 'Desconocido';
    final destinoLat = alert.sensor.destinoLat;
    final destinoLng = alert.sensor.destinoLng;

    Color chipColor;
    String chipLabel;
    switch (alert.estado) {
      case AlertStatus.resuelto:
        chipColor = Colors.green;
        chipLabel = "Resuelto";
        break;
      case AlertStatus.esperandoConfirmacion:
        chipColor = Colors.orange;
        chipLabel = "En proceso";
        break;
      default:
        chipColor = Colors.red;
        chipLabel = "Pendiente";
    }
    print('Detalle alerta: destinoLat=$destinoLat, destinoLng=$destinoLng');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Alerta'),
        backgroundColor: chipColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sensors, color: chipColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        alert.sensor.tipo,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        chipLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: chipColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  alert.mensaje,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _ValueBadge(
                      label: "Anterior",
                      value: alert.valorAnterior.toString(),
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    _ValueBadge(
                      label: "Actual",
                      value: alert.valorActual.toString(),
                      color: chipColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on,
                  label: "Destino",
                  value: destino,
                ),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.person, label: "Cliente", value: cliente),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.inventory_2,
                  label: "ID Paquete",
                  value: paqueteId,
                ),
                const SizedBox(height: 18),
                if (destinoLat != null && destinoLng != null)
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(destinoLat, destinoLng),
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('destino'),
                            position: LatLng(destinoLat, destinoLng),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        liteModeEnabled: false,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Ubicación no disponible'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ValueBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
