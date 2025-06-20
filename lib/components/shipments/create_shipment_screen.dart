import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/package.dart';
import 'package:flutter_agroroute/models/sensor.dart';
import 'package:flutter_agroroute/helpers/helpers.dart';
import 'package:http/http.dart' as http;

const String googleApiKey = 'TU_API_KEY_AQUI';

Future<Map<String, double>?> geocodeAddress(String address) async {
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey',
  );
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'OK') {
      final location = data['results'][0]['geometry']['location'];
      return {'lat': location['lat'], 'lng': location['lng']};
    }
  }
  return null;
}

class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

String generatePackageCode() {
  final random = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
  return 'PQ$random';
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinoController = TextEditingController();
  final List<Package> _paquetes = [];

  bool _ubicacion = true;
  DateTime _fecha = DateTime.now();
  bool _loading = false;

  String generateTrackingNumber() {
    final random = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    return 'TKR$random';
  }

  void _addPackage() async {
    final package = await showDialog<Package>(
      context: context,
      builder: (context) => _PackageDialog(maxDate: _fecha),
    );
    if (package != null) {
      setState(() {
        _paquetes.add(package);
      });
    }
  }

  String _calculateShipmentStatus() {
    if (_paquetes.isEmpty) return "En proceso";
    return _paquetes.every((p) => p.estado.toLowerCase() == "listo")
        ? "Listo"
        : "En proceso";
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paquetes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un paquete')),
      );
      return;
    }
    setState(() => _loading = true);

    final userId = await SecureStorageHelper().userId;
    final trackingNumber = generateTrackingNumber();

    final coords = await geocodeAddress(_destinoController.text);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación del destino'),
        ),
      );
      setState(() => _loading = false);
      return;
    }

    final paquetesMapped = _paquetes.map((p) => p.toJson()).toList();

    final shipmentJson = {
      "trackingNumber": trackingNumber,
      "ownerId": userId,
      "destino": _destinoController.text,
      "fecha": _fecha.toIso8601String(),
      "estado": _calculateShipmentStatus(),
      "ubicacion": _ubicacion,
      "paquetes": paquetesMapped,
      "destinoLat": coords['lat'],
      "destinoLng": coords['lng'],
    };

    try {
      final response = await http.post(
        Uri.parse(
          'https://server-production-e741.up.railway.app/api/v1/shipments',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(shipmentJson),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear envío: ${response.body}')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Envío')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _destinoController,
                decoration: const InputDecoration(labelText: 'Destino'),
                validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
              ),
              SwitchListTile(
                title: const Text('Ubicación activa'),
                value: _ubicacion,
                onChanged: (v) => setState(() => _ubicacion = v),
              ),
              ListTile(
                title: const Text('Fecha de envío'),
                subtitle: Text(_fecha.toLocal().toString().split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _fecha = picked);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('Paquetes:', style: Theme.of(context).textTheme.titleMedium),
              ..._paquetes.map(
                (p) => ListTile(
                  title: Text('Código: ${p.codigo}'),
                  subtitle: Text('Cliente: ${p.cliente} | Estado: ${p.estado}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _paquetes.remove(p);
                      });
                    },
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addPackage,
                icon: const Icon(Icons.add),
                label: const Text('Agregar paquete'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Crear Envío'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageDialog extends StatefulWidget {
  final DateTime maxDate;
  const _PackageDialog({required this.maxDate});

  @override
  State<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<_PackageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _destinoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _pesoController = TextEditingController();
  final _altoController = TextEditingController();
  final _anchoController = TextEditingController();
  final _largoController = TextEditingController();
  DateTime _fecha = DateTime.now();
  final _estadoController = TextEditingController(text: 'En proceso');
  List<Sensor> _sensores = [];

  void _addSensor() async {
    final sensor = await showDialog<Sensor>(
      context: context,
      builder: (context) => const _SensorDialog(),
    );
    if (sensor != null) {
      setState(() {
        _sensores.add(sensor);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Paquete'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _clienteController,
                decoration: const InputDecoration(labelText: 'Cliente'),
                validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
              ),
              TextFormField(
                controller: _destinoController,
                decoration: const InputDecoration(labelText: 'Destino'),
                validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextFormField(
                controller: _pesoController,
                decoration: const InputDecoration(labelText: 'Peso'),
              ),
              TextFormField(
                controller: _altoController,
                decoration: const InputDecoration(labelText: 'Alto'),
              ),
              TextFormField(
                controller: _anchoController,
                decoration: const InputDecoration(labelText: 'Ancho'),
              ),
              TextFormField(
                controller: _largoController,
                decoration: const InputDecoration(labelText: 'Largo'),
              ),
              ListTile(
                title: const Text('Fecha del paquete'),
                subtitle: Text(_fecha.toLocal().toString().split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2020),
                      lastDate: widget.maxDate,
                    );
                    if (picked != null) setState(() => _fecha = picked);
                  },
                ),
              ),
              TextFormField(
                controller: _estadoController,
                decoration: const InputDecoration(labelText: 'Estado'),
                readOnly: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Sensores:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addSensor,
                  ),
                ],
              ),
              ..._sensores.map(
                (s) => ListTile(
                  title: Text('Tipo: ${s.tipo}'),
                  subtitle: Text('Valor: ${s.valor}'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (_fecha.isAfter(widget.maxDate)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La fecha del paquete debe ser menor o igual a la fecha de envío',
                    ),
                  ),
                );
                return;
              }
              final coords = await geocodeAddress(_destinoController.text);
              if (coords == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No se pudo obtener la ubicación del destino del paquete',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                Package(
                  codigo: generatePackageCode(),
                  cliente: _clienteController.text,
                  destino: _destinoController.text,
                  descripcion: _descripcionController.text,
                  peso: _pesoController.text,
                  alto: _altoController.text,
                  ancho: _anchoController.text,
                  largo: _largoController.text,
                  fecha: _fecha,
                  estado: _estadoController.text,
                  sensores: _sensores,
                  destinoLat: coords['lat'],
                  destinoLng: coords['lng'],
                ),
              );
            }
          },
          child: const Text('Agregar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _SensorDialog extends StatefulWidget {
  const _SensorDialog();

  @override
  State<_SensorDialog> createState() => _SensorDialogState();
}

class _SensorDialogState extends State<_SensorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tipoController = TextEditingController();
  final _valorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Sensor'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tipoController,
              decoration: const InputDecoration(labelText: 'Tipo'),
              validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
            ),
            TextFormField(
              controller: _valorController,
              decoration: const InputDecoration(labelText: 'Valor'),
              validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                Sensor(
                  tipo: _tipoController.text,
                  valor: int.tryParse(_valorController.text) ?? 0,
                  activo: true,
                  id: '',
                ),
              );
            }
          },
          child: const Text('Agregar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
