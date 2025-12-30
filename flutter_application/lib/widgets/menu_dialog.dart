import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class MenuDialog extends StatefulWidget {
  final int? tableNumber;
  final String? orderType; // 'DINE_IN', 'TAKEOUT', 'JOINER'
  final String? joinerName;

  const MenuDialog({
    super.key,
    this.tableNumber,
    this.orderType,
    this.joinerName,
  });

  @override
  State<MenuDialog> createState() => _MenuDialogState();
}

class _MenuDialogState extends State<MenuDialog> {
  List<ProductModel> _products = [];
  final Map<String, CartItem> _cart = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _searchQuery = '';

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
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.productTypeName.toLowerCase().contains(_searchQuery.toLowerCase()))
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

  int _getQuantity(String productId) {
    return _cart[productId]?.quantity ?? 0;
  }

  double get _totalAmount {
    return _cart.values.fold(0.0, (sum, item) => sum + item.total);
  }

  void _showCartReview() {
    showDialog(
      context: context,
      builder: (context) => _CartReviewDialog(
        cart: _cart,
        onUpdate: () {
          setState(() {});
        },
        onRemove: (productId) {
          _removeFromCart(productId);
          setState(() {});
        },
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to cart')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String orderType = widget.orderType ?? 'DINE_IN';
      int? tableNumber = widget.tableNumber;

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order created successfully!')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to create order')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Cart icon with badge
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                          onPressed: _cart.isEmpty ? null : _showCartReview,
                          tooltip: 'Review Cart',
                        ),
                        if (_cart.isNotEmpty)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${_cart.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'SEARCH',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 16),

            // Products grid/list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? const Center(child: Text('No products available'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Responsive layout: 3 columns on tablet, 1 column (list) on phone
                            if (constraints.maxWidth < 600) {
                              // Phone: List view (1 column)
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  final quantity = _getQuantity(product.id);
                                  return _ProductListItem(
                                    product: product,
                                    quantity: quantity,
                                    onAdd: () => _addToCart(product),
                                    onRemove: () => _removeFromCart(product.id),
                                  );
                                },
                              );
                            } else {
                              // Tablet: Grid view (3 columns)
                              return GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.1,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  final quantity = _getQuantity(product.id);
                                  return _ProductCard(
                                    product: product,
                                    quantity: quantity,
                                    onAdd: () => _addToCart(product),
                                    onRemove: () => _removeFromCart(product.id),
                                  );
                                },
                              );
                            }
                          },
                        ),
            ),
            const SizedBox(height: 16),

            // Total and Proceed button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total:'),
                      Text(
                        '₱${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting || _cart.isEmpty ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'PROCEED',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - YouTube thumbnail size (smaller)
            Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                      )
                    : const Icon(Icons.restaurant, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),

            // Product name
            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Price
            Text(
              '₱${product.defaultPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),

            // Quantity controls - Bigger buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: quantity > 0 ? onRemove : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: quantity > 0 ? Colors.red[50] : Colors.grey[200],
                      border: Border.all(
                        color: quantity > 0 ? Colors.red[300]! : Colors.grey[400]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 24,
                      color: quantity > 0 ? Colors.red[700] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
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
                  onTap: onAdd,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[300]!, width: 2),
                      borderRadius: BorderRadius.circular(8),
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
  }
}

// List item for phone layout
class _ProductListItem extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductListItem({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Image - YouTube thumbnail size
            Container(
              width: 100,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.restaurant, size: 32, color: Colors.grey),
                      )
                    : const Icon(Icons.restaurant, size: 32, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${product.defaultPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity controls - Bigger buttons
            Row(
              children: [
                InkWell(
                  onTap: quantity > 0 ? onRemove : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: quantity > 0 ? Colors.red[50] : Colors.grey[200],
                      border: Border.all(
                        color: quantity > 0 ? Colors.red[300]! : Colors.grey[400]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 24,
                      color: quantity > 0 ? Colors.red[700] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
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
                  onTap: onAdd,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[300]!, width: 2),
                      borderRadius: BorderRadius.circular(8),
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
  }
}

class _CartReviewDialog extends StatefulWidget {
  final Map<String, CartItem> cart;
  final VoidCallback onUpdate;
  final Function(String) onRemove;

  const _CartReviewDialog({
    required this.cart,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_CartReviewDialog> createState() => _CartReviewDialogState();
}

class _CartReviewDialogState extends State<_CartReviewDialog> {
  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.cart.values.fold(0.0, (sum, item) => sum + item.total);

    return AlertDialog(
      title: const Text(
        'Review Cart',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 600,
        child: widget.cart.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('Cart is empty')),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.cart.length,
                      itemBuilder: (context, index) {
                        final item = widget.cart.values.elementAt(index);
                        return _CartItemTile(
                          item: item,
                          onQuantityIncrease: () {
                            setState(() {
                              item.quantity++;
                            });
                            widget.onUpdate();
                          },
                          onQuantityDecrease: () {
                            if (item.quantity > 1) {
                              setState(() {
                                item.quantity--;
                              });
                              widget.onUpdate();
                            } else {
                              widget.onRemove(item.productId);
                              if (widget.cart.isEmpty) {
                                Navigator.pop(context);
                              } else {
                                setState(() {});
                              }
                            }
                          },
                          onPriceChange: (price) {
                            setState(() {
                              item.unitPrice = price;
                            });
                            widget.onUpdate();
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 32, thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
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
          child: const Text('CLOSE', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatefulWidget {
  final CartItem item;
  final VoidCallback onQuantityIncrease;
  final VoidCallback onQuantityDecrease;
  final Function(double) onPriceChange;

  const _CartItemTile({
    required this.item,
    required this.onQuantityIncrease,
    required this.onQuantityDecrease,
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
  void didUpdateWidget(_CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller if price changed externally
    if (oldWidget.item.unitPrice != widget.item.unitPrice) {
      _priceController.text = widget.item.unitPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name
            Text(
              widget.item.productName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Quantity and price controls
            Row(
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: widget.onQuantityDecrease,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${widget.item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: widget.onQuantityIncrease,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Price editor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price per item',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: '₱',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          final price = double.tryParse(value);
                          if (price != null && price > 0) {
                            widget.onPriceChange(price);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '₱${widget.item.total.toStringAsFixed(2)}',
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
    );
  }
}
