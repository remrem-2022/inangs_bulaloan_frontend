class ProductTypeModel {
  final String id;
  final String typeName;
  final String storeId;

  ProductTypeModel({
    required this.id,
    required this.typeName,
    required this.storeId,
  });

  factory ProductTypeModel.fromJson(Map<String, dynamic> json) {
    return ProductTypeModel(
      id: json['_id'] ?? '',
      typeName: json['typeName'] ?? '',
      storeId: json['storeId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'typeName': typeName,
      'storeId': storeId,
    };
  }
}
