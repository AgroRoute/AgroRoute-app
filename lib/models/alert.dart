import 'package:flutter_agroroute/models/sensor.dart';

enum AlertStatus { pendiente, esperandoConfirmacion, resuelto }

class AlertModel {
  final String id;
  final Sensor sensor;
  final int valorAnterior;
  int valorActual;
  final String mensaje;
  AlertStatus estado;
  final bool bajar;

  AlertModel({
    required this.id,
    required this.sensor,
    required this.valorAnterior,
    required this.valorActual,
    required this.mensaje,
    required this.estado,
    required this.bajar,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final sensorJson = json['sensor'] ?? {};
    String shipmentId = sensorJson['shipmentId']?.toString() ?? '';
    String packageCode = sensorJson['packageCode']?.toString() ?? '';
    String ownerId = sensorJson['ownerId']?.toString() ?? '';
    if ((shipmentId.isEmpty || packageCode.isEmpty || ownerId.isEmpty) &&
        sensorJson['id'] != null) {
      final parts = sensorJson['id'].toString().split('_');
      if (parts.length >= 4) {
        shipmentId = shipmentId.isEmpty ? parts[0] : shipmentId;
        packageCode = packageCode.isEmpty ? parts[1] : packageCode;
        ownerId = ownerId.isEmpty ? parts[2] : ownerId;
      }
    }
    return AlertModel(
      id: json['id'] ?? '',
      sensor: Sensor.fromJson(
        sensorJson,
        shipmentId: shipmentId,
        packageCode: packageCode,
        ownerId: ownerId,
        destino: sensorJson['destino'],
        cliente: sensorJson['cliente'],
        destinoLat: sensorJson['destinoLat'] != null
            ? (sensorJson['destinoLat'] as num).toDouble()
            : null,
        destinoLng: sensorJson['destinoLng'] != null
            ? (sensorJson['destinoLng'] as num).toDouble()
            : null,
      ),
      valorAnterior: json['valorAnterior'] ?? 0,
      valorActual: json['valorActual'] ?? 0,
      mensaje: json['mensaje'] ?? '',
      estado: AlertStatus.values.firstWhere(
        (e) => e.toString() == 'AlertStatus.${json['estado']}',
        orElse: () => AlertStatus.pendiente,
      ),
      bajar: json['bajar'] ?? false,
    );
  }

  Map<String, dynamic> toJson({required String userId}) {
    return {
      'id': id,
      'userId': userId,
      'sensor': sensor.toJson(),
      'valorAnterior': valorAnterior,
      'valorActual': valorActual,
      'mensaje': mensaje,
      'estado': estado.toString().split('.').last,
      'bajar': bajar,
    };
  }
}
