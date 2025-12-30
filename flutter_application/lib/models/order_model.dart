class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  double get total => quantity * unitPrice;
}

class OrderModel {
  final String id;
  final String invoiceNumber;
  final String orderType; // 'DINE_IN', 'TAKEOUT', 'JOINER'
  final int? tableNumber;
  final String? joinerName;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'ACTIVE', 'BILLED_OUT'
  final DateTime? billedOutAt;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.invoiceNumber,
    required this.orderType,
    this.tableNumber,
    this.joinerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.billedOutAt,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      orderType: json['orderType'] ?? '',
      tableNumber: json['tableNumber'],
      joinerName: json['joinerName'],
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      billedOutAt: json['billedOutAt'] != null
          ? DateTime.parse(json['billedOutAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isBilledOut => status == 'BILLED_OUT';
  bool get isDineIn => orderType == 'DINE_IN';
  bool get isTakeout => orderType == 'TAKEOUT';
  bool get isJoiner => orderType == 'JOINER';
}
