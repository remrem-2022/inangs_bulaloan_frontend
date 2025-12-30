import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

class InvoiceScreen extends StatefulWidget {
  final int? initialTableNumber;

  const InvoiceScreen({super.key, this.initialTableNumber});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  int? _selectedTableNumber;
  OrderModel? _mainOrder;
  List<OrderModel> _joiners = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTableNumber != null) {
      _selectedTableNumber = widget.initialTableNumber;
      _loadTableOrders();
    }
  }

  Future<void> _loadTableOrders() async {
    if (_selectedTableNumber == null) return;

    setState(() => _isLoading = true);

    try {
      // Get table details to find main order
      final tableResponse = await ApiService.get(
        ApiConfig.tableDetails(_selectedTableNumber!),
      );

      if (tableResponse['success'] == true &&
          tableResponse['table']['mainOrder'] != null) {
        _mainOrder = OrderModel.fromJson(tableResponse['table']['mainOrder']);
      } else {
        _mainOrder = null;
      }

      // Get joiners
      final joinersResponse = await ApiService.get(
        ApiConfig.tableJoiners(_selectedTableNumber!),
      );

      if (joinersResponse['success'] == true &&
          joinersResponse['joiners'] != null) {
        _joiners = (joinersResponse['joiners'] as List)
            .map((json) => OrderModel.fromJson(json))
            .toList();
      } else {
        _joiners = [];
      }

      setState(() {});
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _billOut(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bill Out'),
        content: Text(
          'Bill out order ${order.invoiceNumber} for ₱${order.totalAmount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bill Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.put(
        ApiConfig.billOutOrder(order.id),
        {},
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order billed out successfully')),
          );
          _loadTableOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to bill out')),
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
          // Table selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Table Number:'),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: DropdownButton<int>(
                    value: _selectedTableNumber,
                    hint: const Text('Select Table'),
                    isExpanded: true,
                    items: List.generate(20, (i) => i + 1)
                        .map((tableNum) => DropdownMenuItem(
                              value: tableNum,
                              child: Text('Table $tableNum'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTableNumber = value;
                        _mainOrder = null;
                        _joiners = [];
                      });
                      if (value != null) {
                        _loadTableOrders();
                      }
                    },
                  ),
                ),
                const Spacer(),
                if (_selectedTableNumber != null)
                  ElevatedButton.icon(
                    onPressed: _loadTableOrders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Orders display
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTableNumber == null
                    ? const Center(child: Text('Please select a table'))
                    : _mainOrder == null && _joiners.isEmpty
                        ? const Center(child: Text('No active orders for this table'))
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_mainOrder != null) ...[
                                const Text(
                                  'Main Customer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _OrderCard(
                                  order: _mainOrder!,
                                  onBillOut: () => _billOut(_mainOrder!),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (_joiners.isNotEmpty) ...[
                                const Text(
                                  'Joiners',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._joiners.map((joiner) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _OrderCard(
                                        order: joiner,
                                        onBillOut: () => _billOut(joiner),
                                      ),
                                    )),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onBillOut;

  const _OrderCard({
    required this.order,
    required this.onBillOut,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order.joinerName != null)
                      Text(
                        order.joinerName!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    Text(
                      DateFormat('MMM dd, yyyy hh:mm a').format(order.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    order.status,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: order.isActive ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const Divider(),
            // Items
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.productName}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '₱${item.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '₱${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₱${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (order.isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onBillOut,
                  icon: const Icon(Icons.receipt),
                  label: const Text('Bill Out'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
