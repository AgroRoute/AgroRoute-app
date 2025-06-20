import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/shipment.dart';
import 'package:flutter_agroroute/helpers/helpers.dart';
import 'package:flutter_agroroute/widgets/agroroute_scaffold.dart';
import 'package:http/http.dart' as http;
import 'package:pie_chart/pie_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Shipment> _shipments = [];
  bool _loading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _enProceso = 0;
  int _listo = 0;
  int _rechazado = 0;

  int _paquetesEnProceso = 0;
  int _paquetesListo = 0;
  int _paquetesRechazado = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchShipments();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchShipments() async {
    setState(() => _loading = true);
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
            .where(
              (s) =>
                  s.ownerId == userId &&
                  (s.estado.toLowerCase() == "en proceso" ||
                      s.estado.toLowerCase() == "listo" ||
                      s.estado.toLowerCase() == "rechazado" ||
                      s.estado.toLowerCase() == "rechazados"),
            )
            .toList();

        int enProceso = 0, listo = 0, rechazado = 0;
        int paquetesEnProceso = 0, paquetesListo = 0, paquetesRechazado = 0;

        for (final s in shipments) {
          final estado = s.estado.toLowerCase();
          if (estado == "en proceso") enProceso++;
          if (estado == "listo") listo++;
          if (estado == "rechazado" || estado == "rechazados") rechazado++;

          for (final p in s.paquetes) {
            final est = p.estado.toLowerCase();
            if (est == "en proceso") paquetesEnProceso++;
            if (est == "listo") paquetesListo++;
            if (est == "rechazado" || est == "rechazados") paquetesRechazado++;
          }
        }

        setState(() {
          _shipments = shipments;
          _enProceso = enProceso;
          _listo = listo;
          _rechazado = rechazado;
          _paquetesEnProceso = paquetesEnProceso;
          _paquetesListo = paquetesListo;
          _paquetesRechazado = paquetesRechazado;
        });

        _animationController.forward();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar envíos: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Map<String, double> dataMap = {
      "En Proceso": _enProceso.toDouble(),
      "Listo": _listo.toDouble(),
      "Rechazados": _rechazado.toDouble(),
    };

    final Map<String, double> paquetesDataMap = {
      "En Proceso": _paquetesEnProceso.toDouble(),
      "Listo": _paquetesListo.toDouble(),
      "Rechazados": _paquetesRechazado.toDouble(),
    };

    return AgroRouteScaffold(
      selectedIndex: 0,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de Envíos',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatsCard(
                            context,
                            title: 'Estado de Envíos',
                            child: PieChart(
                              dataMap: dataMap,
                              colorList: [
                                const Color(0xFFFFD900), // Amarillo
                                const Color(0xFF4CAF50), // Verde
                                const Color(0xFFF44336), // Rojo
                              ],
                              chartType: ChartType.ring,
                              chartRadius: 120,
                              legendOptions: const LegendOptions(
                                showLegends: false,
                              ),
                              chartValuesOptions: const ChartValuesOptions(
                                showChartValues: false,
                              ),
                              gradientList: [
                                [
                                  const Color(0xFFFFD900),
                                  const Color(0xFFFFC107),
                                ],
                                [
                                  const Color(0xFF4CAF50),
                                  const Color(0xFF8BC34A),
                                ],
                                [
                                  const Color(0xFFF44336),
                                  const Color(0xFFE57373),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatusIndicators(
                            enProceso: _enProceso,
                            listo: _listo,
                            rechazado: _rechazado,
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen de Paquetes',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatsCard(
                              context,
                              title: 'Estado de Paquetes',
                              child: PieChart(
                                dataMap: paquetesDataMap,
                                colorList: [
                                  const Color(0xFFFFD900),
                                  const Color(0xFF4CAF50),
                                  const Color(0xFFF44336),
                                ],
                                chartType: ChartType.ring,
                                chartRadius: 120,
                                legendOptions: const LegendOptions(
                                  showLegends: false,
                                ),
                                chartValuesOptions: const ChartValuesOptions(
                                  showChartValues: false,
                                ),
                                gradientList: [
                                  [
                                    const Color(0xFFFFD900),
                                    const Color(0xFFFFC107),
                                  ],
                                  [
                                    const Color(0xFF4CAF50),
                                    const Color(0xFF8BC34A),
                                  ],
                                  [
                                    const Color(0xFFF44336),
                                    const Color(0xFFE57373),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatusIndicators(
                              enProceso: _paquetesEnProceso,
                              listo: _paquetesListo,
                              rechazado: _paquetesRechazado,
                              isPackages: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 20),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar Datos'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _fetchShipments,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicators({
    required int enProceso,
    required int listo,
    required int rechazado,
    bool isPackages = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatusIndicator(
            count: enProceso,
            label: 'En Proceso',
            color: const Color(0xFFFFD900),
            icon: isPackages ? Icons.inventory_2 : Icons.local_shipping,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusIndicator(
            count: listo,
            label: 'Listo',
            color: const Color(0xFF4CAF50),
            icon: isPackages ? Icons.check_circle : Icons.assignment_turned_in,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusIndicator(
            count: rechazado,
            label: 'Rechazado',
            color: const Color(0xFFF44336),
            icon: isPackages ? Icons.cancel : Icons.warning,
          ),
        ),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatusIndicator({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
