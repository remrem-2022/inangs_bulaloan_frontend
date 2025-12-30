import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_config.dart';
import '../../models/product_model.dart';
import '../../models/product_type_model.dart';
import '../../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<ProductModel> _products = [];
  List<ProductTypeModel> _productTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final productsResponse = await ApiService.get(ApiConfig.products);
      final typesResponse = await ApiService.get(ApiConfig.productTypes);

      if (productsResponse['success'] == true &&
          productsResponse['products'] != null) {
        setState(() {
          _products = (productsResponse['products'] as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();
        });
      }

      if (typesResponse['success'] == true &&
          typesResponse['productTypes'] != null) {
        setState(() {
          _productTypes = (typesResponse['productTypes'] as List)
              .map((json) => ProductTypeModel.fromJson(json))
              .toList();
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditProductDialog(
        productTypes: _productTypes,
        onSave: _loadData,
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => _AddEditProductDialog(
        product: product,
        productTypes: _productTypes,
        onSave: _loadData,
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.delete(ApiConfig.productById(product.id));

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to delete product')),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with ADD PRODUCT button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PRODUCTS',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddProductDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('ADD PRODUCT'),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Products Table
                Expanded(
                  child: _products.isEmpty
                      ? const Center(child: Text('No products found'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('PRODUCT NAME')),
                                DataColumn(label: Text('PRODUCT TYPE')),
                                DataColumn(label: Text('PRICE')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              rows: _products.map((product) {
                                final typeName = _productTypes
                                        .firstWhere(
                                          (t) => t.id == product.productTypeId,
                                          orElse: () => ProductTypeModel(
                                            id: '',
                                            typeName: 'Unknown',
                                            storeId: '',
                                          ),
                                        )
                                        .typeName;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(product.name)),
                                    DataCell(Text(typeName)),
                                    DataCell(Text('₱${product.defaultPrice.toStringAsFixed(2)}')),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            onPressed: () => _showEditProductDialog(product),
                                            child: const Text('EDIT'),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => _deleteProduct(product),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('DELETE'),
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

class _AddEditProductDialog extends StatefulWidget {
  final ProductModel? product;
  final List<ProductTypeModel> productTypes;
  final VoidCallback onSave;

  const _AddEditProductDialog({
    this.product,
    required this.productTypes,
    required this.onSave,
  });

  @override
  State<_AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<_AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  String? _selectedTypeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
        text: widget.product?.defaultPrice.toString() ?? '');
    _selectedTypeId = widget.product?.productTypeId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product type')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'defaultPrice': double.parse(_priceController.text),
        'productTypeId': _selectedTypeId,
      };

      final response = widget.product == null
          ? await ApiService.post(ApiConfig.products, data)
          : await ApiService.put(ApiConfig.productById(widget.product!.id), data);

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.product == null
                  ? 'Product created successfully'
                  : 'Product updated successfully'),
            ),
          );
          Navigator.pop(context);
          widget.onSave();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Operation failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'ADD PRODUCT' : 'EDIT PRODUCT'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image placeholder (not implemented yet)
              Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '₱',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedTypeId,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Show the types on the settings > type of product'),
                items: widget.productTypes.map((type) {
                  return DropdownMenuItem(
                    value: type.id,
                    child: Text(type.typeName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTypeId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a type';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('DONE'),
        ),
      ],
    );
  }
}
