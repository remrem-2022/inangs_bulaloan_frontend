class TableModel {
  final String id;
  final int tableNumber;
  final String? currentMainOrderId;
  final String status; // 'available' or 'occupied'
  final String color; // 'GREEN' or 'RED'
  final bool menuEnabled;
  final bool invoiceEnabled;
  final bool joinVisible;

  TableModel({
    required this.id,
    required this.tableNumber,
    this.currentMainOrderId,
    required this.status,
    required this.color,
    required this.menuEnabled,
    required this.invoiceEnabled,
    required this.joinVisible,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['_id'] ?? '',
      tableNumber: json['tableNumber'] ?? 0,
      currentMainOrderId: json['currentMainOrderId'],
      status: json['status'] ?? 'available',
      color: json['color'] ?? 'GREEN',
      menuEnabled: json['menuEnabled'] ?? true,
      invoiceEnabled: json['invoiceEnabled'] ?? false,
      joinVisible: json['joinVisible'] ?? false,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isGreen => color == 'GREEN';
  bool get isRed => color == 'RED';
}
