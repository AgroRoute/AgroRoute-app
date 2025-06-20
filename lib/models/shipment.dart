import 'package:flutter_agroroute/models/package.dart';

class Shipment {
  final String trackingNumber;
  final String ownerId;
  final String destino;
  final DateTime fecha;
  final String estado;
  final bool ubicacion;
  final List<Package> paquetes;
  final double? destinoLat;
  final double? destinoLng;

  Shipment({
    required this.trackingNumber,
    required this.ownerId,
    required this.destino,
    required this.fecha,
    required this.estado,
    required this.ubicacion,
    required this.paquetes,
    this.destinoLat,
    this.destinoLng,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      trackingNumber: json['trackingNumber'],
      ownerId: json['ownerId'].toString(),
      destino: json['destino'],
      fecha: DateTime.parse(json['fecha']),
      estado: json['estado'],
      ubicacion: json['ubicacion'],
      paquetes: (json['paquetes'] as List)
          .map(
            (p) => Package.fromJson(
              p,
              shipmentId: json['trackingNumber'],
              ownerId: json['ownerId'].toString(),
            ),
          )
          .toList(),
      destinoLat: json['destinoLat'] != null
          ? (json['destinoLat'] as num).toDouble()
          : null,
      destinoLng: json['destinoLng'] != null
          ? (json['destinoLng'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackingNumber': trackingNumber,
      'ownerId': ownerId,
      'destino': destino,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'ubicacion': ubicacion,
      'paquetes': paquetes.map((p) => p.toJson()).toList(),
      if (destinoLat != null) 'destinoLat': destinoLat,
      if (destinoLng != null) 'destinoLng': destinoLng,
    };
  }
}
