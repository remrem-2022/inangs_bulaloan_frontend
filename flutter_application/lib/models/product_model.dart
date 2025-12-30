class ProductModel {
  final String id;
  final String name;
  final double defaultPrice;
  final String productTypeId;
  final String productTypeName;
  final String? imageUrl;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    required this.defaultPrice,
    required this.productTypeId,
    required this.productTypeName,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      defaultPrice: (json['defaultPrice'] ?? 0).toDouble(),
      productTypeId: json['productTypeId'] ?? '',
      productTypeName: json['productTypeName'] ?? '',
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
