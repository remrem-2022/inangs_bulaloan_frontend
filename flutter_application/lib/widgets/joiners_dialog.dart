import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import 'menu_dialog.dart';

class JoinersDialog extends StatefulWidget {
  final int tableNumber;
  final VoidCallback onJoinerAdded;

  const JoinersDialog({
    super.key,
    required this.tableNumber,
    required this.onJoinerAdded,
  });

  @override
  State<JoinersDialog> createState() => _JoinersDialogState();
}

class _JoinersDialogState extends State<JoinersDialog> {
  final TextEditingController _nameController = TextEditingController();
  List<OrderModel> _joiners = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadJoiners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadJoiners() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(
        ApiConfig.tableJoiners(widget.tableNumber),
      );

      if (response['success'] == true && response['joiners'] != null) {
        setState(() {
          _joiners = (response['joiners'] as List)
              .map((json) => OrderModel.fromJson(json))
              .toList();
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openMenuForJoiner() async {
    final joinerName = _nameController.text.trim();

    if (joinerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter joiner name')),
      );
      return;
    }

    // Close this dialog and open menu dialog
    Navigator.of(context).pop();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MenuDialog(
        tableNumber: widget.tableNumber,
        orderType: 'JOINER',
        joinerName: joinerName,
      ),
    );

    if (result == true) {
      widget.onJoinerAdded();
    }
  }

  void _showJoinersList() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TABLE ${widget.tableNumber} - JOINERS',
                    style: const TextStyle(
                      fontSize: 18,
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
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_joiners.isEmpty)
                const Center(child: Text('No joiners yet'))
              else
                ..._joiners.map((joiner) => ListTile(
                      title: Text(joiner.joinerName ?? 'Unknown'),
                      subtitle: Text('Invoice: ${joiner.invoiceNumber}'),
                      trailing: Text(
                        '₱${joiner.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'JOIN TABLE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Joiner name input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'JOINERS NAME',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _openMenuForJoiner,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('MENU'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showJoinersList,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('TABLE ${widget.tableNumber}\nJOINERS LIST'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Done button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
