import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class InvoiceDialog extends StatefulWidget {
  final int tableNumber;

  const InvoiceDialog({super.key, required this.tableNumber});

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
        _joiners =
            (joinersResponse['joiners'] as List)
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

  Future<void> _addItemsToOrder(OrderModel order) async {
    // Open edit order dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EditOrderDialog(order: order),
    );

    if (result == true) {
      // Reload orders to show updated totals
      await _loadTableOrders();
    }
  }

  Future<void> _billOut(OrderModel order) async {
    // Step 1: Show cash input dialog
    final cashController = TextEditingController();
    final cash = await showDialog<double>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cash Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount: ₱${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cashController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Cash Received',
                    prefixText: '₱',
                    border: OutlineInputBorder(),
                    hintText: '',
                  ),
                  onSubmitted: (value) {
                    final amount = double.tryParse(value);
                    if (amount != null && amount >= order.totalAmount) {
                      Navigator.pop(context, amount);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(cashController.text);
                  if (amount == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                    return;
                  }
                  if (amount < order.totalAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insufficient cash amount')),
                    );
                    return;
                  }
                  Navigator.pop(context, amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
    );

    if (cash == null) return;

    // Step 2: Calculate change
    final change = cash - order.totalAmount;

    // Step 3: Show change dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Bill Out'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaymentRow('Total Amount:', order.totalAmount),
                const SizedBox(height: 8),
                _buildPaymentRow('Cash Received:', cash),
                const Divider(height: 24),
                _buildPaymentRow(
                  'Change:',
                  change,
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Bill Out'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Step 4: Send to backend with cash amount
    try {
      final response = await ApiService.put(ApiConfig.billOutOrder(order.id), {
        'cash': cash,
      });

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
            SnackBar(
              content: Text(response['message'] ?? 'Failed to bill out'),
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

  Widget _buildPaymentRow(
    String label,
    double amount, {
    Color? color,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child:
            _isLoading
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
                              onAddItems: () => _addItemsToOrder(_mainOrder!),
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
                            ..._joiners.map(
                              (joiner) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _InvoiceCard(
                                  order: joiner,
                                  onAddItems: () => _addItemsToOrder(joiner),
                                  onBillOut: () => _billOut(joiner),
                                ),
                              ),
                            ),
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
  final VoidCallback onAddItems;
  final VoidCallback onBillOut;

  const _InvoiceCard({
    required this.order,
    required this.onAddItems,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Expanded(
                child: Text(
                  'ITEM',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                width: 70,
                child: Text(
                  'PRICE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 80,
                child: Text(
                  'AMOUNT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items List
          ...order.items.map(
            (item) => Padding(
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
            ),
          ),

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

          // Add Items and Bill Out buttons (only for active orders)
          if (order.isActive) ...[
            const SizedBox(height: 24),
            // EDIT ORDER button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAddItems,
                icon: const Icon(Icons.edit, size: 24),
                label: const Text(
                  'EDIT ORDER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // BILL OUT button
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

// Widget for editing order items
class _EditOrderDialog extends StatefulWidget {
  final OrderModel order;

  const _EditOrderDialog({required this.order});

  @override
  State<_EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<_EditOrderDialog> {
  List<ProductModel> _products = [];
  final Map<String, _CartItem> _cart = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _initializeCartFromOrder();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeCartFromOrder() {
    // Pre-populate cart with existing order items
    for (var item in widget.order.items) {
      _cart[item.productId] = _CartItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      );
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(ApiConfig.menuProducts);

      if (response['success'] == true && response['products'] != null) {
        final products =
            (response['products'] as List)
                .map((json) => ProductModel.fromJson(json))
                .toList();

        setState(() {
          _products = products;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<ProductModel> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _addToCart(ProductModel product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = _CartItem(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitPrice: product.defaultPrice,
        );
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId]!.quantity > 1) {
          _cart[productId]!.quantity--;
        } else {
          _cart.remove(productId);
        }
      }
    });
  }

  int _getQuantity(String productId) {
    return _cart[productId]?.quantity ?? 0;
  }

  Future<void> _submitItems() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order must have at least one item')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.put(
        ApiConfig.addItemsToOrder(widget.order.id),
        {'items': _cart.values.map((item) => item.toJson()).toList()},
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order updated successfully!')),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to update order'),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _editPrice(String productId, String productName, double currentPrice) {
    final controller = TextEditingController(
      text: currentPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Price - $productName'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '₱',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newPrice = double.tryParse(controller.text);
                  if (newPrice != null && newPrice > 0) {
                    setState(() {
                      _cart[productId]!.unitPrice = newPrice;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EDIT ORDER',
                          style: TextStyle(
                            fontSize: 24,
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

                    // Search field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final quantity = _getQuantity(product.id);
                          final cartItem = _cart[product.id];
                          final displayPrice =
                              cartItem?.unitPrice ?? product.defaultPrice;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Product image
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          product.imageUrl != null
                                              ? Image.network(
                                                product.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.restaurant,
                                                      size: 32,
                                                      color: Colors.grey,
                                                    ),
                                              )
                                              : const Icon(
                                                Icons.restaurant,
                                                size: 32,
                                                color: Colors.grey,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Product details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap:
                                              quantity > 0
                                                  ? () => _editPrice(
                                                    product.id,
                                                    product.name,
                                                    displayPrice,
                                                  )
                                                  : null,
                                          child: Row(
                                            children: [
                                              Text(
                                                '₱${displayPrice.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      quantity > 0
                                                          ? Colors.green
                                                          : Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (quantity > 0) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.edit,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quantity controls
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap:
                                            quantity > 0
                                                ? () =>
                                                    _removeFromCart(product.id)
                                                : null,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color:
                                                quantity > 0
                                                    ? Colors.red[50]
                                                    : Colors.grey[200],
                                            border: Border.all(
                                              color:
                                                  quantity > 0
                                                      ? Colors.red[300]!
                                                      : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 24,
                                            color:
                                                quantity > 0
                                                    ? Colors.red[700]
                                                    : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 50,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          border: Border.all(
                                            color: Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$quantity',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      InkWell(
                                        onTap: () => _addToCart(product),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            border: Border.all(
                                              color: Colors.green[300]!,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 24,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Submit button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'UPDATE ORDER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

// Cart item class for add items dialog
class _CartItem {
  final String productId;
  final String productName;
  int quantity;
  double unitPrice;

  _CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

// Custom painter for dashed lines
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey[400]!
          ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
