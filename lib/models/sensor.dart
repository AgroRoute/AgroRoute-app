class Sensor {
  final String tipo;
  int valor;
  final bool activo;
  final String id;
  final String? destino;
  final String? cliente;
  final String? packageCode;
  final double? destinoLat;
  final double? destinoLng;

  Sensor({
    required this.tipo,
    required this.valor,
    required this.activo,
    required this.id,
    this.destino,
    this.cliente,
    this.packageCode,
    this.destinoLat,
    this.destinoLng,
  });

  factory Sensor.fromJson(
    Map<String, dynamic> json, {
    required String shipmentId,
    required String packageCode,
    required String ownerId,
    String? destino,
    String? cliente,
    double? destinoLat,
    double? destinoLng,
  }) {
    return Sensor(
      tipo: json['tipo'],
      valor: json['valor'] is int
          ? json['valor']
          : int.tryParse(json['valor'].toString()) ?? 0,
      activo: json['activo'] ?? false,
      id: '${shipmentId}_${packageCode}_${ownerId}_${json['tipo']}',
      destino: destino,
      cliente: cliente,
      packageCode: packageCode,
      destinoLat: destinoLat,
      destinoLng: destinoLng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'valor': valor,
      'activo': activo,
      'id': id,
      if (destino != null) 'destino': destino,
      if (cliente != null) 'cliente': cliente,
      if (packageCode != null) 'packageCode': packageCode,
      if (destinoLat != null) 'destinoLat': destinoLat, // <-- Agrega esto
      if (destinoLng != null) 'destinoLng': destinoLng, // <-- Agrega esto
    };
  }
}
