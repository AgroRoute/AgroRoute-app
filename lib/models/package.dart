import 'package:flutter_agroroute/models/sensor.dart';

class Package {
  final String codigo;
  final String cliente;
  final String destino;
  final String descripcion;
  final String peso;
  final String alto;
  final String ancho;
  final String largo;
  final DateTime fecha;
  final String estado;
  final List<Sensor> sensores;
  final double? destinoLat;
  final double? destinoLng;
  final int? shipmentId;

  Package({
    required this.codigo,
    required this.cliente,
    required this.destino,
    required this.descripcion,
    required this.peso,
    required this.alto,
    required this.ancho,
    required this.largo,
    required this.fecha,
    required this.estado,
    required this.sensores,
    this.destinoLat,
    this.destinoLng,
    this.shipmentId,
  });

  factory Package.fromJson(
    Map<String, dynamic> json, {
    required String shipmentId,
    required String ownerId,
  }) {
    return Package(
      codigo: json['codigo'],
      cliente: json['cliente'],
      destino: json['destino'],
      descripcion: json['descripcion'],
      peso: json['peso'],
      alto: json['alto'],
      ancho: json['ancho'],
      largo: json['largo'],
      fecha: DateTime.parse(json['fecha']),
      estado: json['estado'],
      sensores: (json['sensores'] as List)
          .map(
            (s) => Sensor.fromJson(
              s,
              shipmentId: shipmentId,
              packageCode: json['codigo'],
              ownerId: ownerId,
              destino: json['destino'],
              cliente: json['cliente'],
              destinoLat: json['destinoLat'] != null
                  ? (json['destinoLat'] as num).toDouble()
                  : null,
              destinoLng: json['destinoLng'] != null
                  ? (json['destinoLng'] as num).toDouble()
                  : null,
            ),
          )
          .toList(),
      destinoLat: json['destinoLat'] != null
          ? (json['destinoLat'] as num).toDouble()
          : null,
      destinoLng: json['destinoLng'] != null
          ? (json['destinoLng'] as num).toDouble()
          : null,
      shipmentId: json['shipmentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'cliente': cliente,
      'destino': destino,
      'descripcion': descripcion,
      'peso': peso,
      'alto': alto,
      'ancho': ancho,
      'largo': largo,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'shipmentId': shipmentId,
      'sensores': sensores.map((s) => s.toJson()).toList(),
      if (destinoLat != null) 'destinoLat': destinoLat,
      if (destinoLng != null) 'destinoLng': destinoLng,
    };
  }
}
