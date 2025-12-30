import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../../config/api_config.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  PlutoGridStateManager? _stateManager;

  late List<PlutoColumn> _columns;
  List<PlutoRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _loadOrders();
  }

  void _initializeColumns() {
    _columns = [
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.text(),
        width: 0,
        hide: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'INVOICE #',
        field: 'invoice',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'DATE/TIME',
        field: 'date',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'TYPE',
        field: 'type',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'TABLE',
        field: 'table',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'STATUS',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final status = rendererContext.cell.value;
          final isActive = status == 'ACTIVE';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.green[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? Colors.green[300]! : Colors.grey[400]!,
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isActive ? Colors.green[700] : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'TOTAL PURCHASE',
        field: 'total',
        type: PlutoColumnType.currency(symbol: '₱'),
        width: 200,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'ACTIONS',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: 250,
        enableEditingMode: false,
        renderer: (rendererContext) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  final orderId = rendererContext.row.cells['id']?.value;
                  final order = _orders.firstWhere((o) => o.id == orderId);
                  _showOrderDetails(order);
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('VIEW'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  final orderId = rendererContext.row.cells['id']?.value;
                  final order = _orders.firstWhere((o) => o.id == orderId);
                  _deleteOrder(order);
                },
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('DELETE'),
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
              ),
            ],
          );
        },
      ),
    ];
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(ApiConfig.orders);

      if (response['success'] == true && response['orders'] != null) {
        _orders =
            (response['orders'] as List)
                .map((json) => OrderModel.fromJson(json))
                .toList();

        _updateRows();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateRows() {
    _rows =
        _orders.map((order) {
          return PlutoRow(
            cells: {
              'id': PlutoCell(value: order.id),
              'invoice': PlutoCell(value: order.invoiceNumber),
              'date': PlutoCell(
                value: DateFormat(
                  'MMM dd, yyyy hh:mm a',
                ).format(order.createdAt),
              ),
              'type': PlutoCell(value: order.orderType),
              'table': PlutoCell(value: order.tableNumber?.toString() ?? '-'),
              'status': PlutoCell(value: order.status),
              'total': PlutoCell(value: order.totalAmount),
              'actions': PlutoCell(value: ''),
            },
          );
        }).toList();

    _stateManager?.removeAllRows();
    _stateManager?.appendRows(_rows);
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Order ${order.invoiceNumber}'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('Type:', order.orderType),
                  if (order.tableNumber != null)
                    _InfoRow('Table:', order.tableNumber.toString()),
                  if (order.joinerName != null)
                    _InfoRow('Joiner:', order.joinerName!),
                  _InfoRow('Status:', order.status),
                  _InfoRow(
                    'Created:',
                    DateFormat('MMM dd, yyyy hh:mm a').format(order.createdAt),
                  ),
                  if (order.billedOutAt != null)
                    _InfoRow(
                      'Billed Out:',
                      DateFormat(
                        'MMM dd, yyyy hh:mm a',
                      ).format(order.billedOutAt!),
                    ),
                  const Divider(),
                  const Text(
                    'Items:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.productName}'),
                          Text('₱${item.total.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Order'),
            content: Text(
              'Are you sure you want to delete order ${order.invoiceNumber}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.delete(
        '${ApiConfig.orders}/${order.id}',
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order deleted successfully')),
          );
          _loadOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to delete order'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Professional Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.orange[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.list_alt,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ORDERS',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '${_orders.length} orders',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _loadOrders,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text(
                            'REFRESH',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange[700],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PlutoGrid Table
                  Expanded(
                    child:
                        _orders.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.list_alt_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No orders found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Container(
                              padding: const EdgeInsets.all(16),
                              child: PlutoGrid(
                                columns: _columns,
                                rows: _rows,
                                onLoaded: (PlutoGridOnLoadedEvent event) {
                                  _stateManager = event.stateManager;
                                  _stateManager!.setShowColumnFilter(true);
                                },
                                configuration: PlutoGridConfiguration(
                                  style: PlutoGridStyleConfig(
                                    gridBorderRadius: BorderRadius.circular(12),
                                    gridBorderColor: Colors.grey[300]!,
                                    activatedBorderColor: Colors.orange[300]!,
                                    activatedColor: Colors.orange[50]!,
                                    gridBackgroundColor: Colors.white,
                                    rowColor: Colors.white,
                                    oddRowColor: Colors.grey[50],
                                    columnTextStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    cellTextStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    columnHeight: 50,
                                    rowHeight: 55,
                                    defaultColumnTitlePadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                    defaultCellPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                    enableColumnBorderVertical: false,
                                    enableColumnBorderHorizontal: true,
                                    borderColor: Colors.grey[200]!,
                                    inactivatedBorderColor: Colors.grey[300]!,
                                    iconColor: Colors.orange[700]!,
                                    disabledIconColor: Colors.grey,
                                    menuBackgroundColor: Colors.white,
                                    gridPopupBorderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  columnFilter: PlutoGridColumnFilterConfig(
                                    filters: const [
                                      ...FilterHelper.defaultFilters,
                                    ],
                                    resolveDefaultColumnFilter: (
                                      column,
                                      resolver,
                                    ) {
                                      return resolver<PlutoFilterTypeContains>()
                                          as PlutoFilterType;
                                    },
                                  ),
                                ),
                                createHeader:
                                    (stateManager) => Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Search and filter orders using the column filters below',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              ),
                            ),
                  ),
                ],
              ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
