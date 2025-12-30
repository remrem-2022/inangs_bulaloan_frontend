class UserModel {
  final String id;
  final String username;
  final String role;
  final String? storeId;
  final String? storeName;
  final String? storeAddress;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.storeId,
    this.storeName,
    this.storeAddress,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      storeId: json['storeId'],
      storeName: json['storeName'],
      storeAddress: json['storeAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'role': role,
      'storeId': storeId,
      'storeName': storeName,
      'storeAddress': storeAddress,
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
}
