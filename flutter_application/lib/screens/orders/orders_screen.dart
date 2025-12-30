import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      String url = ApiConfig.orders;
      if (_filterStatus != 'ALL') {
        url += '?status=$_filterStatus';
      }

      final response = await ApiService.get(url);

      if (response['success'] == true && response['orders'] != null) {
        final orders = (response['orders'] as List)
            .map((json) => OrderModel.fromJson(json))
            .toList();

        setState(() {
          _orders = orders;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOrderDetails(OrderModel order) {

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              if (order.joinerName != null) _InfoRow('Joiner:', order.joinerName!),
              _InfoRow('Status:', order.status),
              _InfoRow('Created:',
                  DateFormat('MMM dd, yyyy hh:mm a').format(order.createdAt)),
              if (order.billedOutAt != null)
                _InfoRow('Billed Out:',
                    DateFormat('MMM dd, yyyy hh:mm a').format(order.billedOutAt!)),
              const Divider(),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.quantity}x ${item.productName}'),
                        Text('₱${item.total.toStringAsFixed(2)}'),
                      ],
                    ),
                  )),
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete order ${order.invoiceNumber}?'),
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
      final response = await ApiService.delete('${ApiConfig.orders}/${order.id}');

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order deleted successfully')),
          );
          _loadOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to delete order')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ORDERS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text('Total: ${_orders.length}'),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _loadOrders,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(child: Text('No orders found'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                            columns: const [
                              DataColumn(label: Text('invoice #')),
                              DataColumn(label: Text('date/time')),
                              DataColumn(label: Text('type')),
                              DataColumn(label: Text('order')),
                              DataColumn(label: Text('total purchase')),
                              DataColumn(label: Text('actions')),
                            ],
                            rows: _orders.map((order) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(order.invoiceNumber)),
                                  DataCell(
                                    Text(DateFormat('MM/dd/yyyy').format(order.createdAt)),
                                  ),
                                  DataCell(
                                    Text(order.orderType.toLowerCase()),
                                  ),
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () => _showOrderDetails(order),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text('show order'),
                                    ),
                                  ),
                                  DataCell(
                                    Text(order.totalAmount.toStringAsFixed(2)),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: () => _showOrderDetails(order),
                                          child: const Text('edit'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () => _deleteOrder(order),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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
