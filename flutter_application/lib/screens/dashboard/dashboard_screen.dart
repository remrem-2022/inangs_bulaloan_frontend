import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load orders to calculate stats
      final ordersResponse = await ApiService.get(ApiConfig.orders);
      final tablesResponse = await ApiService.get(ApiConfig.tables);

      if (ordersResponse['success'] == true) {
        final orders = ordersResponse['orders'] as List;

        // Calculate today's stats
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final todayOrders = orders.where((o) {
          final createdAt = DateTime.parse(o['createdAt']);
          return createdAt.isAfter(today);
        }).toList();

        final activeOrders = orders.where((o) => o['status'] == 'ACTIVE').length;

        double todayRevenue = 0;
        for (var order in todayOrders) {
          if (order['status'] == 'BILLED_OUT') {
            todayRevenue += (order['totalAmount'] as num).toDouble();
          }
        }

        setState(() {
          _stats = {
            'todayOrders': todayOrders.length,
            'todayRevenue': todayRevenue,
            'activeOrders': activeOrders,
            'totalOrders': orders.length,
          };
        });
      }

      if (tablesResponse['success'] == true) {
        final tables = tablesResponse['tables'] as List;
        final occupiedTables = tables.where((t) => t['status'] == 'occupied').length;

        setState(() {
          _stats['occupiedTables'] = occupiedTables;
          _stats['totalTables'] = tables.length;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 28),
                  onPressed: _loadDashboardData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Stats Grid - Optimized for Tablet
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 4;
                if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                } else if (constraints.maxWidth < 1200) {
                  crossAxisCount = 3;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                      title: "Today's Orders",
                      value: _stats['todayOrders']?.toString() ?? '0',
                      icon: Icons.shopping_cart_outlined,
                      color: Colors.blue[700]!,
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _StatCard(
                      title: "Today's Revenue",
                      value: '₱${(_stats['todayRevenue'] ?? 0).toStringAsFixed(2)}',
                      icon: Icons.payments_outlined,
                      color: Colors.green[700]!,
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _StatCard(
                      title: 'Active Orders',
                      value: _stats['activeOrders']?.toString() ?? '0',
                      icon: Icons.receipt_long_outlined,
                      color: Colors.orange[700]!,
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.orange[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _StatCard(
                      title: 'Tables Occupied',
                      value: '${_stats['occupiedTables'] ?? 0} / ${_stats['totalTables'] ?? 0}',
                      icon: Icons.table_restaurant_outlined,
                      color: Colors.purple[700]!,
                      gradient: LinearGradient(
                        colors: [Colors.purple[400]!, Colors.purple[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

