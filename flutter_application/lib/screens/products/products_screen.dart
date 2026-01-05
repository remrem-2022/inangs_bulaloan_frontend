import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
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
  PlutoGridStateManager? _stateManager;

  late List<PlutoColumn> _columns;
  List<PlutoRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _loadData();
  }

  void _initializeColumns() {
    _columns = [
      // Hidden ID column for reference
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.text(),
        width: 0,
        hide: true,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PRODUCT NAME',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 250,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PRODUCT TYPE',
        field: 'type',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'PRICE',
        field: 'price',
        type: PlutoColumnType.currency(symbol: '₱'),
        width: 150,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'AVAILABLE',
        field: 'available',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final productId = rendererContext.row.cells['id']?.value;
          final product = _products.firstWhere((p) => p.id == productId);

          return Center(
            child: Switch(
              value: product.isAvailable,
              onChanged: (value) {
                _toggleAvailability(product);
              },
              activeColor: Colors.green,
            ),
          );
        },
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
                  final productId = rendererContext.row.cells['id']?.value;
                  final product = _products.firstWhere(
                    (p) => p.id == productId,
                  );
                  _showEditProductDialog(product);
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('EDIT'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  final productId = rendererContext.row.cells['id']?.value;
                  final product = _products.firstWhere(
                    (p) => p.id == productId,
                  );
                  _deleteProduct(product);
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final productsResponse = await ApiService.get(ApiConfig.products);
      final typesResponse = await ApiService.get(ApiConfig.productTypes);

      if (productsResponse['success'] == true &&
          productsResponse['products'] != null) {
        _products =
            (productsResponse['products'] as List)
                .map((json) => ProductModel.fromJson(json))
                .toList();
      }

      if (typesResponse['success'] == true &&
          typesResponse['productTypes'] != null) {
        _productTypes =
            (typesResponse['productTypes'] as List)
                .map((json) => ProductTypeModel.fromJson(json))
                .toList();
      }

      _updateRows();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateRows() {
    _rows =
        _products.map((product) {
          final typeName =
              _productTypes
                  .firstWhere(
                    (t) => t.id == product.productTypeId,
                    orElse:
                        () => ProductTypeModel(
                          id: '',
                          typeName: 'Unknown',
                          storeId: '',
                        ),
                  )
                  .typeName;

          return PlutoRow(
            cells: {
              'id': PlutoCell(value: product.id),
              'name': PlutoCell(value: product.name),
              'type': PlutoCell(value: typeName),
              'price': PlutoCell(value: product.defaultPrice),
              'available': PlutoCell(value: product.isAvailable ? 'Yes' : 'No'),
              'actions': PlutoCell(value: ''),
            },
          );
        }).toList();

    _stateManager?.removeAllRows();
    _stateManager?.appendRows(_rows);
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _AddEditProductDialog(
            productTypes: _productTypes,
            onSave: _loadData,
          ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    showDialog(
      context: context,
      builder:
          (context) => _AddEditProductDialog(
            product: product,
            productTypes: _productTypes,
            onSave: _loadData,
          ),
    );
  }

  Future<void> _toggleAvailability(ProductModel product) async {
    try {
      final response = await ApiService.patch(
        ApiConfig.toggleProductAvailability(product.id),
        {},
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Product ${product.isAvailable ? "unavailable" : "available"} now',
              ),
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Failed to update availability',
              ),
            ),
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

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text('Are you sure you want to delete "${product.name}"?'),
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
        ApiConfig.productById(product.id),
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to delete product'),
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
                        colors: [Colors.green[400]!, Colors.green[700]!],
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
                              Icons.inventory_2,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PRODUCTS',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '${_products.length} products',
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
                          onPressed: _showAddProductDialog,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text(
                            'ADD PRODUCT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green[700],
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
                        _products.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click "ADD PRODUCT" to create your first product',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
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
                                    activatedBorderColor: Colors.blue[300]!,
                                    activatedColor: Colors.blue[50]!,
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
                                    iconColor: Colors.blue[700]!,
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
                                      if (column.field == 'actions') {
                                        return resolver<
                                              PlutoFilterTypeContains
                                            >()
                                            as PlutoFilterType;
                                      }
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
                                            'Search and filter products using the column filters below',
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
      text: widget.product?.defaultPrice.toString() ?? '',
    );
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

      final response =
          widget.product == null
              ? await ApiService.post(ApiConfig.products, data)
              : await ApiService.put(
                ApiConfig.productById(widget.product!.id),
                data,
              );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.product == null
                    ? 'Product created successfully'
                    : 'Product updated successfully',
              ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                hint: const Text(
                  'Show the types on the settings > type of product',
                ),
                items:
                    widget.productTypes.map((type) {
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
          child:
              _isSubmitting
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
