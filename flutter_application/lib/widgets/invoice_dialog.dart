import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class InvoiceDialog extends StatefulWidget {
  final int tableNumber;

  const InvoiceDialog({
    super.key,
    required this.tableNumber,
  });

  @override
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  OrderModel? _mainOrder;
  List<OrderModel> _joiners = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTableOrders();
  }

  Future<void> _loadTableOrders() async {
    setState(() => _isLoading = true);

    try {
      // Get table details to find main order
      final tableResponse = await ApiService.get(
        ApiConfig.tableDetails(widget.tableNumber),
      );

      if (tableResponse['success'] == true &&
          tableResponse['table']['mainOrder'] != null) {
        _mainOrder = OrderModel.fromJson(tableResponse['table']['mainOrder']);
      } else {
        _mainOrder = null;
      }

      // Get joiners
      final joinersResponse = await ApiService.get(
        ApiConfig.tableJoiners(widget.tableNumber),
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

          // Reload orders
          await _loadTableOrders();

          // If no more active orders, close dialog
          if (_mainOrder == null && _joiners.isEmpty) {
            if (mounted) {
              Navigator.of(context).pop(true); // Return true to refresh tables
            }
          }
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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _mainOrder == null && _joiners.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No active orders for this table'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TABLE ${widget.tableNumber} - INVOICES',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Orders list
                      Expanded(
                        child: ListView(
                          children: [
                            if (_mainOrder != null) ...[
                              const Text(
                                'Main Customer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _InvoiceCard(
                                order: _mainOrder!,
                                onBillOut: () => _billOut(_mainOrder!),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (_joiners.isNotEmpty) ...[
                              const Text(
                                'Joiners',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._joiners.map((joiner) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _InvoiceCard(
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
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onBillOut;

  const _InvoiceCard({
    required this.order,
    required this.onBillOut,
  });

  Widget _buildDashedLine() {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Store Header
          const Text(
            'INANGS BULALOAN',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'RECEIPT',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),

          // Invoice Number and Date
          _buildDashedLine(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invoice: ${order.invoiceNumber}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (order.joinerName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    order.joinerName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDashedLine(),
          const SizedBox(height: 20),

          // Items Header
          Row(
            children: [
              const SizedBox(
                width: 40,
                child: Text(
                  'QTY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'ITEM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                width: 70,
                child: Text(
                  'PRICE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 80,
                child: Text(
                  'AMOUNT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items List
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '₱${item.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '₱${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 20),
          _buildDashedLine(),
          const SizedBox(height: 16),

          // Total Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL AMOUNT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
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

          const SizedBox(height: 16),
          _buildDashedLine(),

          // Bill Out button (only for active orders)
          if (order.isActive) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onBillOut,
                icon: const Icon(Icons.receipt_long, size: 24),
                label: const Text(
                  'BILL OUT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'PAID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Thank you message
          const SizedBox(height: 24),
          Text(
            '* * * THANK YOU * * *',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for dashed lines
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
