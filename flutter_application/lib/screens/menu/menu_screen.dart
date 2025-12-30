import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_config.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';

class MenuScreen extends StatefulWidget {
  final int? tableNumber;
  final String? orderType; // 'DINE_IN', 'TAKEOUT', 'JOINER'
  final String? joinerName;

  const MenuScreen({
    super.key,
    this.tableNumber,
    this.orderType,
    this.joinerName,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<ProductModel> _products = [];
  final Map<String, CartItem> _cart = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(ApiConfig.menuProducts);

      if (response['success'] == true && response['products'] != null) {
        final products = (response['products'] as List)
            .map((json) => ProductModel.fromJson(json))
            .toList();

        setState(() {
          _products = products;
          if (_products.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _products.first.productTypeName;
          }
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    return _products.map((p) => p.productTypeName).toSet().toList();
  }

  List<ProductModel> get _filteredProducts {
    if (_selectedCategory == null) return [];
    return _products
        .where((p) => p.productTypeName == _selectedCategory)
        .toList();
  }

  void _addToCart(ProductModel product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = CartItem(
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

  void _updatePrice(String productId, double newPrice) {
    setState(() {
      if (_cart.containsKey(productId)) {
        _cart[productId]!.unitPrice = newPrice;
      }
    });
  }

  double get _totalAmount {
    return _cart.values.fold(0.0, (sum, item) => sum + item.total);
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      _showMessage('Please add items to cart');
      return;
    }

    // Determine order type and validate
    String orderType = widget.orderType ?? 'DINE_IN';
    int? tableNumber = widget.tableNumber;

    if (orderType == 'DINE_IN' && tableNumber == null) {
      // Ask for table number
      final result = await _showTableNumberDialog();
      if (result == null) return;
      tableNumber = result;
    } else if (orderType == 'JOINER' && tableNumber == null) {
      _showMessage('Table number required for joiner');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String endpoint;
      Map<String, dynamic> orderData = {
        'items': _cart.values.map((item) => item.toJson()).toList(),
      };

      if (orderType == 'DINE_IN') {
        endpoint = ApiConfig.dineInOrders;
        orderData['tableNumber'] = tableNumber;
      } else if (orderType == 'TAKEOUT') {
        endpoint = ApiConfig.takeoutOrders;
      } else {
        endpoint = ApiConfig.joinerOrders;
        orderData['tableNumber'] = tableNumber;
        orderData['joinerName'] = widget.joinerName ?? 'Guest';
      }

      final response = await ApiService.post(endpoint, orderData);

      if (mounted) {
        if (response['success'] == true) {
          _showMessage('Order created successfully!');
          setState(() => _cart.clear());
          Navigator.of(context).pop(true); // Return to previous screen
        } else {
          _showMessage(response['message'] ?? 'Failed to create order');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<int?> _showTableNumberDialog() async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Table Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Table Number',
            border: OutlineInputBorder(),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tableNum = int.tryParse(controller.text);
              if (tableNum != null) {
                Navigator.pop(context, tableNum);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _cart.isEmpty ? null : _showCartDialog,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Category sidebar
                SizedBox(
                  width: 200,
                  child: ListView(
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return ListTile(
                        title: Text(category),
                        selected: isSelected,
                        onTap: () {
                          setState(() => _selectedCategory = category);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Products grid
                Expanded(
                  flex: 3,
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('No products available'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _ProductCard(
                              product: product,
                              onAdd: () => _addToCart(product),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Amount:'),
                        Text(
                          '₱${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(() => _cart.clear()),
                          child: const Text('Clear Cart'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitOrder,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Submit Order'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cart Items'),
        content: SizedBox(
          width: 500,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _cart.length,
            itemBuilder: (context, index) {
              final item = _cart.values.elementAt(index);
              return _CartItemTile(
                item: item,
                onAdd: () => setState(() => item.quantity++),
                onRemove: () => _removeFromCart(item.productId),
                onPriceChange: (price) => _updatePrice(item.productId, price),
              );
            },
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
}

class CartItem {
  final String productId;
  final String productName;
  int quantity;
  double unitPrice;

  CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.restaurant, size: 64),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₱${product.defaultPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatefulWidget {
  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Function(double) onPriceChange;

  const _CartItemTile({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.onPriceChange,
  });

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.item.unitPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.item.productName),
      subtitle: Row(
        children: [
          SizedBox(
            width: 100,
            child: TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '₱',
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final price = double.tryParse(value);
                if (price != null) {
                  widget.onPriceChange(price);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Text('Total: ₱${widget.item.total.toStringAsFixed(2)}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: widget.onRemove,
          ),
          Text('${widget.item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: widget.onAdd,
          ),
        ],
      ),
    );
  }
}
