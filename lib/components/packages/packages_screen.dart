import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_agroroute/models/package.dart';
import 'package:flutter_agroroute/models/shipment.dart';
import 'package:flutter_agroroute/components/packages/packages_detail_screen.dart';
import 'package:flutter_agroroute/widgets/agroroute_scaffold.dart';
import 'package:http/http.dart' as http;

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  List<Package> _packages = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPackages();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPackages() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://server-production-e741.up.railway.app/api/v1/shipments',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final shipments = data.map((e) => Shipment.fromJson(e)).toList();
        final packages = <Package>[];
        for (final shipment in shipments) {
          packages.addAll(shipment.paquetes);
        }
        setState(() {
          _packages = packages;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar paquetes: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Package> get _filteredPackages {
    if (_searchQuery.isEmpty) return _packages;
    return _packages.where((pkg) {
      final codigo = pkg.codigo.toLowerCase();
      final cliente = pkg.cliente.toLowerCase();
      final destino = pkg.destino.toLowerCase();
      final estado = pkg.estado.toLowerCase();
      final fecha = pkg.fecha.toString().toLowerCase();
      return codigo.contains(_searchQuery) ||
          cliente.contains(_searchQuery) ||
          destino.contains(_searchQuery) ||
          estado.contains(_searchQuery) ||
          fecha.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredPackages = _filteredPackages;

    return AgroRouteScaffold(
      selectedIndex: 2,
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
                  'Mis Paquetes',
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
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeaderDelegate(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar paquetes...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : filteredPackages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 60,
                      color: theme.disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No tienes paquetes registrados'
                          : 'No se encontraron resultados',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchPackages,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = filteredPackages[index];
                    return _PackageCard(
                      package: pkg,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PackagesDetailScreen(package: pkg),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Package package;
  final VoidCallback onTap;

  const _PackageCard({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Código: ${package.codigo}",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(package.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(package.estado).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      package.estado.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(package.estado),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PackageInfoRow(
                icon: Icons.person_outline,
                label: 'Cliente',
                value: package.cliente,
              ),
              const SizedBox(height: 8),
              _PackageInfoRow(
                icon: Icons.place,
                label: 'Destino',
                value: package.destino,
              ),
              const SizedBox(height: 8),
              _PackageInfoRow(
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: package.fecha.toLocal().toString().split(' ')[0],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: const Color(0xFF2D4F2B),
                  ),
                  label: Text(
                    'VER DETALLES',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2D4F2B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en proceso':
        return const Color(0xFFFFA000);
      case 'listo':
        return const Color(0xFF4CAF50);
      case 'rechazado':
      case 'rechazados':
        return const Color(0xFFF44336);
      case 'entregado':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

class _PackageInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PackageInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(text: value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: shrinkOffset > 0 ? 2 : 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
