import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/shipment.dart';
import 'package:flutter_agroroute/models/sensor.dart';
import 'package:flutter_agroroute/models/alert.dart';
import 'package:flutter_agroroute/helpers/helpers.dart';
import 'package:flutter_agroroute/widgets/agroroute_scaffold.dart';
import 'package:flutter_agroroute/components/alerts/alerts_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = true;
  Timer? _timer;
  List<Sensor> _userSensors = [];
  final Map<String, int> _sensorThresholds = {};
  final Map<String, int> _originalValues = {};

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    await _fetchSensors();
    await _fetchUserAlerts();
    setState(() => _loading = false);

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _simulateSensorChange();
    });
  }

  Future<void> _fetchSensors() async {
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
            .where((s) => s.ownerId == userId)
            .toList();

        final List<Sensor> sensors = [];
        for (final shipment in shipments) {
          for (final pkg in shipment.paquetes) {
            for (final sensor in pkg.sensores) {
              sensors.add(sensor);
              _sensorThresholds[sensor.id] ??= 50;
              _originalValues[sensor.id] ??= sensor.valor;
            }
          }
        }
        _userSensors = sensors;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar sensores: $e')));
    }
  }

  Future<void> _fetchUserAlerts() async {
    final userId = await SecureStorageHelper().userId;
    final response = await http.get(
      Uri.parse(
        'https://server-production-e741.up.railway.app/api/v1/alerts/$userId',
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _alerts = data.map((a) => AlertModel.fromJson(a)).toList();
        });
      }
    }
  }

  Future<void> _saveAlert(AlertModel alert) async {
    final userId = await SecureStorageHelper().userId;
    await http.post(
      Uri.parse('https://server-production-e741.up.railway.app/api/v1/alerts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(alert.toJson(userId: userId)),
    );
    await _fetchUserAlerts();
  }

  Future<void> _updateAlert(AlertModel alert) async {
    await http.patch(
      Uri.parse(
        'https://server-production-e741.up.railway.app/api/v1/alerts/${alert.id}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'estado': alert.estado.toString().split('.').last,
        'valorActual': alert.valorActual,
      }),
    );
    await _fetchUserAlerts();
  }

  void _simulateSensorChange() {
    if (_userSensors.isEmpty) return;
    final random = Random();
    final sensor = _userSensors[random.nextInt(_userSensors.length)];
    final sensorKey = sensor.id;
    final int valorActual = sensor.valor;

    final existeAlertaActiva = _alerts.any(
      (a) =>
          a.sensor.id == sensorKey &&
          (a.estado == AlertStatus.pendiente ||
              a.estado == AlertStatus.esperandoConfirmacion),
    );
    if (existeAlertaActiva) return;

    final threshold = _sensorThresholds[sensorKey] ?? 15;
    final original = _originalValues[sensorKey] ?? valorActual;

    final bool bajar = random.nextBool();
    int nuevoValor;
    if (bajar) {
      nuevoValor = valorActual - random.nextInt(10) - 1;
    } else {
      nuevoValor = valorActual + random.nextInt(10) + 1;
    }

    bool hayAlerta = false;
    String mensaje = '';
    if (bajar && nuevoValor < threshold) {
      hayAlerta = true;
      mensaje =
          'Sensor ${sensor.tipo} ha bajado su valor, se le recomienda verificar el sensor para que regrese a su valor';
    } else if (!bajar && nuevoValor > threshold) {
      hayAlerta = true;
      mensaje =
          'Sensor ${sensor.tipo} ha subido su valor, se le recomienda verificar el sensor para que regrese a su valor';
    }

    if (hayAlerta) {
      final alert = AlertModel(
        id: '${sensor.id}_${DateTime.now().millisecondsSinceEpoch}',
        sensor: sensor,
        valorAnterior: valorActual,
        valorActual: nuevoValor,
        mensaje: mensaje,
        estado: AlertStatus.pendiente,
        bajar: bajar,
      );
      setState(() {
        sensor.valor = nuevoValor;
      });
      _saveAlert(alert);
    }
  }

  void _handleManual(AlertModel alert) {
    setState(() {
      alert.estado = AlertStatus.esperandoConfirmacion;
    });
    _updateAlert(alert);

    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() {
        alert.estado = AlertStatus.resuelto;
        alert.resueltoManual = true;
        alert.fechaResuelto = DateTime.now();
      });
      _updateAlert(alert);
    });
  }

  void _handleAutomatic(AlertModel alert) {
    final sensorKey = alert.sensor.id;
    final original = _originalValues[sensorKey] ?? alert.valorAnterior;
    setState(() {
      alert.sensor.valor = original;
      alert.estado = AlertStatus.resuelto;
      alert.resueltoManual = false;
      alert.fechaResuelto = DateTime.now();
      alert.valorActual = original;
    });
    _updateAlert(alert);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activas = _alerts
        .where(
          (a) =>
              a.estado == AlertStatus.pendiente ||
              a.estado == AlertStatus.esperandoConfirmacion,
        )
        .toList();
    final resueltas = _alerts
        .where((a) => a.estado == AlertStatus.resuelto)
        .toList();

    return AgroRouteScaffold(
      selectedIndex: 3,
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
                  'Alertas',
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
          ];
        },
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Alertas activas",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      activas.isEmpty
                          ? Center(
                              child: Text(
                                'No hay alertas activas',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final alert = activas[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AlertsDetailScreen(alert: alert),
                                      ),
                                    );
                                  },
                                  child: _AlertCard(
                                    alert: alert,
                                    onManual: () => _handleManual(alert),
                                    onAutomatic: () => _handleAutomatic(alert),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 30),
                      Text(
                        "Alertas resueltas",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      resueltas.isEmpty
                          ? Center(
                              child: Text(
                                'No hay alertas resueltas',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: resueltas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final alert = resueltas[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AlertsDetailScreen(alert: alert),
                                      ),
                                    );
                                  },
                                  child: _AlertCard(
                                    alert: alert,
                                    onManual: () {},
                                    onAutomatic: () {},
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onManual;
  final VoidCallback onAutomatic;

  const _AlertCard({
    required this.alert,
    required this.onManual,
    required this.onAutomatic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color borderColor;
    IconData icon;
    Color iconColor;
    String chipLabel;
    Color chipColor;
    Color chipTextColor;

    switch (alert.estado) {
      case AlertStatus.resuelto:
        bgColor = Colors.green.withOpacity(0.07);
        borderColor = Colors.green;
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        chipLabel = "Resuelto";
        chipColor = Colors.green.withOpacity(0.15);
        chipTextColor = Colors.green;
        break;
      case AlertStatus.esperandoConfirmacion:
        bgColor = Colors.orange.withOpacity(0.07);
        borderColor = Colors.orange;
        icon = Icons.hourglass_top_rounded;
        iconColor = Colors.orange;
        chipLabel = "Esperando confirmación";
        chipColor = Colors.orange.withOpacity(0.15);
        chipTextColor = Colors.orange;
        break;
      default:
        bgColor = Colors.red.withOpacity(0.07);
        borderColor = Colors.red;
        icon = alert.bajar
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
        iconColor = alert.bajar ? Colors.blue : Colors.red;
        chipLabel = "Pendiente";
        chipColor = Colors.red.withOpacity(0.15);
        chipTextColor = Colors.red;
    }

    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.13),
                  child: Icon(icon, color: iconColor, size: 28),
                  radius: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    alert.mensaje,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    chipLabel,
                    style: TextStyle(
                      color: chipTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: chipColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                  color: borderColor,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sensors, color: theme.primaryColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        alert.sensor.tipo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (alert.estado == AlertStatus.pendiente)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onManual,
                    child: const Text('Hacerlo Manual'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAutomatic,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF708A58),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Hacerlo Automático'),
                  ),
                ],
              ),
            if (alert.estado == AlertStatus.esperandoConfirmacion)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Esperando que el usuario confirme la solución manual.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (alert.estado == AlertStatus.resuelto)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Alerta resuelta automáticamente.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
