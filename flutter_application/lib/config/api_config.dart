class ApiConfig {
  // Backend API base URL
  static const String baseUrl =
      'https://inangs-bulaloan-backend.onrender.com/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String getCurrentUser = '$baseUrl/auth/me';

  // Store endpoints
  static const String stores = '$baseUrl/stores';

  // Product type endpoints
  static const String productTypes = '$baseUrl/product-types';
  static String productTypeById(String id) => '$baseUrl/product-types/$id';

  // Product endpoints
  static const String products = '$baseUrl/products';
  static const String menuProducts = '$baseUrl/products/menu';
  static String productById(String id) => '$baseUrl/products/$id';

  // Table endpoints
  static const String tables = '$baseUrl/tables';

  // Order endpoints
  static const String orders = '$baseUrl/orders';
  static const String dineInOrders = '$baseUrl/orders/dine-in';
  static const String takeoutOrders = '$baseUrl/orders/takeout';
  static const String joinerOrders = '$baseUrl/orders/joiner';

  // Helper to get order add-items endpoint
  static String addItemsToOrder(String orderId) =>
      '$baseUrl/orders/$orderId/add-items';

  // Helper to get order bill-out endpoint
  static String billOutOrder(String orderId) =>
      '$baseUrl/orders/$orderId/bill-out';

  // Helper to get table details endpoint
  static String tableDetails(int tableNumber) => '$baseUrl/tables/$tableNumber';

  // Helper to get table joiners endpoint
  static String tableJoiners(int tableNumber) =>
      '$baseUrl/tables/$tableNumber/joiners';
}
