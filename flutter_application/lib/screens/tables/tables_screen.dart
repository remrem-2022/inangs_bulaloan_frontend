import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../models/table_model.dart';
import '../../services/api_service.dart';
import '../../widgets/menu_dialog.dart';
import '../../widgets/invoice_dialog.dart';
import '../../widgets/joiners_dialog.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<TableModel> _tables = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(ApiConfig.tables);

      if (response['success'] == true && response['tables'] != null) {
        final tables = (response['tables'] as List)
            .map((json) => TableModel.fromJson(json))
            .toList();

        setState(() {
          _tables = tables;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showTakeoutMenu() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const MenuDialog(orderType: 'TAKEOUT'),
    );

    if (result == true) {
      _loadTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No tables found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTables,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header with TAKE OUT button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tables',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your restaurant tables',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showTakeoutMenu,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  label: const Text(
                    'TAKE OUT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: Colors.green.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Tables grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTables,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid columns based on screen width
                  int crossAxisCount = 5;
                  if (constraints.maxWidth < 600) {
                    crossAxisCount = 2; // Phone portrait
                  } else if (constraints.maxWidth < 900) {
                    crossAxisCount = 3; // Phone landscape / Small tablet
                  } else if (constraints.maxWidth < 1200) {
                    crossAxisCount = 4; // Medium tablet
                  } else {
                    crossAxisCount = 5; // Large tablet / Desktop
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _tables.length,
                    itemBuilder: (context, index) {
                      final table = _tables[index];
                      return _TableCard(
                        table: table,
                        onRefresh: _loadTables,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onRefresh;

  const _TableCard({
    required this.table,
    required this.onRefresh,
  });

  Future<void> _navigateToMenu(BuildContext context, int tableNumber) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MenuDialog(
        tableNumber: tableNumber,
        orderType: 'DINE_IN',
      ),
    );

    if (result == true) {
      onRefresh();
    }
  }

  Future<void> _navigateToInvoice(BuildContext context, int tableNumber) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => InvoiceDialog(tableNumber: tableNumber),
    );

    if (result == true) {
      onRefresh();
    }
  }

  Future<void> _showJoinDialog(BuildContext context, int tableNumber) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => JoinersDialog(
        tableNumber: tableNumber,
        onJoinerAdded: onRefresh,
      ),
    );

    if (result == true) {
      onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = table.isGreen ? Colors.green[600]! : Colors.red[600]!;
    final lightBgColor = table.isGreen ? Colors.green[50]! : Colors.red[50]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Table Number
            Text(
              'Table ${table.tableNumber}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            // Status Indicator
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: table.isGreen
                      ? [Colors.green[400]!, Colors.green[700]!]
                      : [Colors.red[400]!, Colors.red[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                table.isGreen ? Icons.check_circle_outline : Icons.people_alt,
                color: Colors.white,
                size: 40,
              ),
            ),

            // Status Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: lightBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: bgColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                table.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: bgColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

            // Action Buttons
            Column(
              children: [
                if (table.menuEnabled)
                  _ActionButton(
                    label: 'MENU',
                    icon: Icons.restaurant_menu,
                    color: Colors.blue[600]!,
                    onPressed: () => _navigateToMenu(context, table.tableNumber),
                  ),
                if (table.invoiceEnabled) ...[
                  const SizedBox(height: 8),
                  _ActionButton(
                    label: 'INVOICE',
                    icon: Icons.receipt_long,
                    color: Colors.orange[600]!,
                    onPressed: () => _navigateToInvoice(context, table.tableNumber),
                  ),
                ],
                if (table.joinVisible) ...[
                  const SizedBox(height: 8),
                  _ActionButton(
                    label: 'JOIN',
                    icon: Icons.group_add,
                    color: Colors.purple[600]!,
                    onPressed: () => _showJoinDialog(context, table.tableNumber),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
