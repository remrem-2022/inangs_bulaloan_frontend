import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_config.dart';
import '../../models/product_type_model.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _showProductTypes = false;
  List<ProductTypeModel> _productTypes = [];
  late TextEditingController _numberOfTablesController;
  int _originalNumberOfTables = 0;

  @override
  void initState() {
    super.initState();
    _numberOfTablesController = TextEditingController();
    _loadSettings();
    _loadProductTypes();
  }

  @override
  void dispose() {
    _numberOfTablesController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get('${ApiConfig.baseUrl}/settings');

      if (response['success'] == true && response['settings'] != null) {
        final settings = response['settings'];
        setState(() {
          _originalNumberOfTables = settings['numberOfTables'] ?? 10;
          _numberOfTablesController.text = _originalNumberOfTables.toString();
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProductTypes() async {
    try {
      final response = await ApiService.get(ApiConfig.productTypes);

      if (response['success'] == true && response['productTypes'] != null) {
        setState(() {
          _productTypes = (response['productTypes'] as List)
              .map((json) => ProductTypeModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveSettings() async {
    final newNumberOfTables = int.tryParse(_numberOfTablesController.text);

    if (newNumberOfTables == null || newNumberOfTables < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of tables')),
      );
      return;
    }

    try {
      final response = await ApiService.put(
        '${ApiConfig.baseUrl}/settings',
        {'numberOfTables': newNumberOfTables},
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
          _loadSettings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to save settings')),
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

  void _showAddProductTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => _ProductTypeDialog(
        onSave: _loadProductTypes,
      ),
    );
  }

  void _showEditProductTypeDialog(ProductTypeModel type) {
    showDialog(
      context: context,
      builder: (context) => _ProductTypeDialog(
        productType: type,
        onSave: _loadProductTypes,
      ),
    );
  }

  Future<void> _deleteProductType(ProductTypeModel type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product Type'),
        content: Text('Are you sure you want to delete "${type.typeName}"?'),
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
      final response = await ApiService.delete(ApiConfig.productTypeById(type.id));

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product type deleted successfully')),
          );
          _loadProductTypes();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to delete')),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTINGS',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Number of Tables
                  Text(
                    'NO. OF TABLES',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _numberOfTablesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Product Types Section
                  Text(
                    'TYPE OF PRODUCT',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showProductTypes = !_showProductTypes;
                      });
                    },
                    child: Text(_showProductTypes ? 'HIDE LIST' : 'SHOW LIST'),
                  ),
                  const SizedBox(height: 16),

                  // Product Types List (if shown)
                  if (_showProductTypes) ...[
                    Container(
                      width: 400,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.grey[200],
                            child: const Row(
                              children: [
                                Expanded(child: Text('TYPE NAME', style: TextStyle(fontWeight: FontWeight.bold))),
                                SizedBox(width: 100, child: Text('EDIT', style: TextStyle(fontWeight: FontWeight.bold))),
                                SizedBox(width: 100, child: Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          // Product Types
                          if (_productTypes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No product types found'),
                            )
                          else
                            ..._productTypes.map((type) => Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey[300]!),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(type.typeName)),
                                      SizedBox(
                                        width: 100,
                                        child: TextButton(
                                          onPressed: () => _showEditProductTypeDialog(type),
                                          child: const Text('EDIT'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: TextButton(
                                          onPressed: () => _deleteProductType(type),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('DELETE'),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          // Add button
                          Container(
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showAddProductTypeDialog,
                              child: const Text('ADD'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('SAVE SETTINGS'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProductTypeDialog extends StatefulWidget {
  final ProductTypeModel? productType;
  final VoidCallback onSave;

  const _ProductTypeDialog({
    this.productType,
    required this.onSave,
  });

  @override
  State<_ProductTypeDialog> createState() => _ProductTypeDialogState();
}

class _ProductTypeDialogState extends State<_ProductTypeDialog> {
  late TextEditingController _typeNameController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _typeNameController = TextEditingController(text: widget.productType?.typeName ?? '');
  }

  @override
  void dispose() {
    _typeNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final typeName = _typeNameController.text.trim();

    if (typeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a type name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {'typeName': typeName};

      final response = widget.productType == null
          ? await ApiService.post(ApiConfig.productTypes, data)
          : await ApiService.put(ApiConfig.productTypeById(widget.productType!.id), data);

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.productType == null
                  ? 'Product type created successfully'
                  : 'Product type updated successfully'),
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
      title: Text(widget.productType == null ? 'Add Product Type' : 'Edit Product Type'),
      content: TextField(
        controller: _typeNameController,
        decoration: const InputDecoration(
          labelText: 'Type Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
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
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
