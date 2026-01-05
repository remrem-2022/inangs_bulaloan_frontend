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
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;

              return Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: isSmallScreen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tables',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage your restaurant tables',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showTakeoutMenu,
                              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                              label: const Text(
                                'TAKE OUT',
                                style: TextStyle(
                                  fontSize: 14,
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
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
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
              );
            },
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
                  double horizontalPadding = 24;
                  double cardWidth = 200;

                  if (constraints.maxWidth < 600) {
                    crossAxisCount = 2; // Phone portrait
                    horizontalPadding = 16;
                    cardWidth = (constraints.maxWidth - horizontalPadding * 2 - 16) / 2;
                  } else if (constraints.maxWidth < 900) {
                    crossAxisCount = 3; // Phone landscape / Small tablet
                    horizontalPadding = 20;
                    cardWidth = (constraints.maxWidth - horizontalPadding * 2 - 40) / 3;
                  } else if (constraints.maxWidth < 1200) {
                    crossAxisCount = 4; // Medium tablet
                    cardWidth = (constraints.maxWidth - 48 - 60) / 4;
                  } else {
                    crossAxisCount = 5; // Large tablet / Desktop
                    cardWidth = (constraints.maxWidth - 48 - 80) / 5;
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Wrap(
                      spacing: horizontalPadding * 0.8,
                      runSpacing: horizontalPadding * 0.8,
                      children: _tables.map((table) {
                        return SizedBox(
                          width: cardWidth,
                          child: _TableCard(
                            table: table,
                            onRefresh: _loadTables,
                            isSmallScreen: constraints.maxWidth < 600,
                          ),
                        );
                      }).toList(),
                    ),
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
  final bool isSmallScreen;

  const _TableCard({
    required this.table,
    required this.onRefresh,
    this.isSmallScreen = false,
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

    // Responsive sizing - more aggressive on small screens
    final cardPadding = isSmallScreen ? 10.0 : 20.0;
    final tableFontSize = isSmallScreen ? 16.0 : 24.0;
    final circleSize = isSmallScreen ? 50.0 : 80.0;
    final iconSize = isSmallScreen ? 26.0 : 40.0;
    final statusFontSize = isSmallScreen ? 9.0 : 12.0;
    final statusPadding = isSmallScreen ? 10.0 : 16.0;
    final buttonSpacing = isSmallScreen ? 5.0 : 8.0;
    final elementSpacing = isSmallScreen ? 6.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
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
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Table Number
            Text(
              'Table ${table.tableNumber}',
              style: TextStyle(
                fontSize: tableFontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                height: 1.0,
              ),
            ),

            SizedBox(height: elementSpacing),

            // Status Indicator
            Container(
              width: circleSize,
              height: circleSize,
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
                size: iconSize,
              ),
            ),

            SizedBox(height: elementSpacing),

            // Status Text
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: statusPadding,
                vertical: isSmallScreen ? 3 : 6,
              ),
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
                  fontSize: statusFontSize,
                  color: bgColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  height: 1.0,
                ),
              ),
            ),

            SizedBox(height: elementSpacing),

            // Action Buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (table.menuEnabled)
                  _ActionButton(
                    label: 'MENU',
                    icon: Icons.restaurant_menu,
                    color: Colors.blue[600]!,
                    onPressed: () => _navigateToMenu(context, table.tableNumber),
                    isSmallScreen: isSmallScreen,
                  ),
                if (table.invoiceEnabled) ...[
                  SizedBox(height: buttonSpacing),
                  _ActionButton(
                    label: 'INVOICE',
                    icon: Icons.receipt_long,
                    color: Colors.orange[600]!,
                    onPressed: () => _navigateToInvoice(context, table.tableNumber),
                    isSmallScreen: isSmallScreen,
                  ),
                ],
                if (table.joinVisible) ...[
                  SizedBox(height: buttonSpacing),
                  _ActionButton(
                    label: 'JOIN',
                    icon: Icons.group_add,
                    color: Colors.purple[600]!,
                    onPressed: () => _showJoinDialog(context, table.tableNumber),
                    isSmallScreen: isSmallScreen,
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
  final bool isSmallScreen;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = isSmallScreen ? 32.0 : 44.0;
    final iconSize = isSmallScreen ? 14.0 : 18.0;
    final fontSize = isSmallScreen ? 11.0 : 14.0;
    final horizontalPadding = isSmallScreen ? 6.0 : 12.0;
    final verticalPadding = isSmallScreen ? 4.0 : 8.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        label: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
        ),
      ),
    );
  }
}
