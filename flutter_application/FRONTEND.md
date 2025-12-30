# FRONTEND DOCUMENTATION - Inang's Bulaloan Restaurant System

## Tech Stack
- **Framework**: Flutter
- **HTTP Client**: http package
- **Authentication**: JWT with secure storage
- **Data Grid**: pluto_grid package
- **State Management**: Provider / StatefulWidget (your choice)

## Required Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0  # For JWT token storage
  provider: ^6.1.1  # State management
  pluto_grid: ^8.0.0  # Data grid for tables
  intl: ^0.19.0  # Date formatting
```

---

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── settings.dart
│   ├── product_type.dart
│   ├── product.dart
│   ├── table.dart
│   └── order.dart
├── services/                 # API services
│   ├── api_client.dart       # HTTP client with JWT
│   ├── auth_service.dart
│   ├── settings_service.dart
│   ├── product_type_service.dart
│   ├── product_service.dart
│   ├── table_service.dart
│   └── order_service.dart
├── screens/                  # Main screens
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart  # Main screen with tabs
│   ├── tables/
│   │   └── tables_tab.dart
│   ├── products/
│   │   └── products_tab.dart
│   ├── orders/
│   │   └── orders_tab.dart
│   ├── settings/
│   │   └── settings_tab.dart
│   └── profile/
│       └── profile_tab.dart
├── widgets/                  # Reusable widgets
│   ├── table_card.dart       # Individual table widget
│   ├── menu_dialog.dart      # Menu selection dialog
│   ├── invoice_dialog.dart   # Invoice display dialog
│   ├── joiners_dialog.dart   # Joiners management dialog
│   ├── joiners_list_dialog.dart
│   ├── product_type_dialog.dart
│   ├── product_form_dialog.dart
│   └── product_item_card.dart
└── utils/                    # Utilities
    ├── constants.dart        # API URLs, colors
    └── formatters.dart       # Currency, date formatters
```

---

## DATA MODELS

### 1. User Model (`models/user.dart`)
```dart
class User {
  final String id;
  final String username;
  final String role;  // 'admin' or 'staff'

  User({required this.id, required this.username, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      role: json['role'],
    );
  }
}
```

### 2. Settings Model (`models/settings.dart`)
```dart
class Settings {
  final String id;
  final int numberOfTables;
  final int nextInvoiceNumber;

  Settings({
    required this.id,
    required this.numberOfTables,
    required this.nextInvoiceNumber,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      id: json['_id'],
      numberOfTables: json['numberOfTables'],
      nextInvoiceNumber: json['nextInvoiceNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numberOfTables': numberOfTables,
    };
  }
}
```

### 3. ProductType Model (`models/product_type.dart`)
```dart
class ProductType {
  final String id;
  final String typeName;
  final bool isDeleted;

  ProductType({
    required this.id,
    required this.typeName,
    this.isDeleted = false,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: json['_id'],
      typeName: json['typeName'],
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'typeName': typeName};
  }
}
```

### 4. Product Model (`models/product.dart`)
```dart
class Product {
  final String id;
  final String name;
  final double defaultPrice;
  final String productTypeId;
  final String? productTypeName;  // Populated from join
  final String? imageUrl;
  final bool isAvailable;
  final bool isDeleted;

  Product({
    required this.id,
    required this.name,
    required this.defaultPrice,
    required this.productTypeId,
    this.productTypeName,
    this.imageUrl,
    this.isAvailable = true,
    this.isDeleted = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      defaultPrice: json['defaultPrice'].toDouble(),
      productTypeId: json['productTypeId'],
      productTypeName: json['productTypeName'],
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'defaultPrice': defaultPrice,
      'productTypeId': productTypeId,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}
```

### 5. Table Model (`models/table.dart`)
```dart
class TableModel {
  final String id;
  final int tableNumber;
  final String? currentMainOrderId;
  final String status;  // 'available' or 'occupied'

  // Computed properties from backend
  final String color;  // 'GREEN' or 'RED'
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
      id: json['_id'],
      tableNumber: json['tableNumber'],
      currentMainOrderId: json['currentMainOrderId'],
      status: json['status'],
      color: json['color'],
      menuEnabled: json['menuEnabled'],
      invoiceEnabled: json['invoiceEnabled'],
      joinVisible: json['joinVisible'],
    );
  }
}
```

### 6. Order Model (`models/order.dart`)
```dart
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
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
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

  double get subtotal => quantity * unitPrice;
}

class Order {
  final String id;
  final String invoiceNumber;
  final String orderType;  // 'DINE_IN', 'TAKEOUT', 'JOINER'
  final int? tableNumber;
  final String? joinerName;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;  // 'ACTIVE', 'BILLED_OUT'
  final DateTime createdAt;
  final DateTime? billedOutAt;

  Order({
    required this.id,
    required this.invoiceNumber,
    required this.orderType,
    this.tableNumber,
    this.joinerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.billedOutAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      invoiceNumber: json['invoiceNumber'],
      orderType: json['orderType'],
      tableNumber: json['tableNumber'],
      joinerName: json['joinerName'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      billedOutAt: json['billedOutAt'] != null
          ? DateTime.parse(json['billedOutAt'])
          : null,
    );
  }

  String get displayType {
    switch (orderType) {
      case 'DINE_IN':
        return 'dine in-table $tableNumber';
      case 'TAKEOUT':
        return 'take out';
      case 'JOINER':
        return 'join-table $tableNumber';
      default:
        return orderType;
    }
  }
}
```

---

## SERVICES

### 1. API Client (`services/api_client.dart`)
```dart
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:5000/api';
  final storage = FlutterSecureStorage();

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: 'jwt_token', value: token);
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> getHeaders({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET request
  Future<http.Response> get(String endpoint) async {
    final headers = await getHeaders();
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  // POST request
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // PUT request
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // PATCH request
  Future<http.Response> patch(String endpoint, [Map<String, dynamic>? body]) async {
    final headers = await getHeaders();
    return await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // DELETE request
  Future<http.Response> delete(String endpoint) async {
    final headers = await getHeaders();
    return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
}
```

### 2. Auth Service (`services/auth_service.dart`)
```dart
class AuthService {
  final ApiClient _client = ApiClient();

  Future<User> login(String username, String password) async {
    final response = await _client.post('/auth/login', {
      'username': username,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _client.saveToken(data['token']);
      return User.fromJson(data['user']);
    } else {
      throw Exception('Login failed');
    }
  }

  Future<void> logout() async {
    await _client.deleteToken();
  }

  Future<User?> getCurrentUser() async {
    final response = await _client.get('/auth/me');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    }
    return null;
  }
}
```

### Other Services
- `SettingsService` - GET/PUT settings
- `ProductTypeService` - CRUD for product types
- `ProductService` - CRUD for products, toggle availability
- `TableService` - Get tables, get joiners
- `OrderService` - Create orders, bill out, get history

---

## SCREENS

### 1. Login Screen (`screens/auth/login_screen.dart`)
```
┌─────────────────────────────────────┐
│                                     │
│      INANG'S BULALOAN               │
│      Restaurant System              │
│                                     │
│  Username: [________________]       │
│  Password: [________________]       │
│                                     │
│            [LOGIN]                  │
│                                     │
└─────────────────────────────────────┘
```

### 2. Home Screen (`screens/home/home_screen.dart`)
Main screen with bottom navigation or tabs:
- Tables
- Products
- Orders
- Settings
- Profile

### 3. Tables Tab (`screens/tables/tables_tab.dart`)
```
┌─────────────────────────────────────────────────────┐
│  TABLES                        [TAKE OUT]           │
│                                                     │
│  Grid of Table Cards (responsive)                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐              │
│  │ TABLE 1 │ │ TABLE 2 │ │ TABLE 3 │              │
│  │  (RED)  │ │ (GREEN) │ │ (GREEN) │              │
│  │  [MENU] │ │  [MENU] │ │  [MENU] │              │
│  │[INVOICE]│ │[INVOICE]│ │[INVOICE]│              │
│  │  [JOIN] │ │         │ │         │              │
│  └─────────┘ └─────────┘ └─────────┘              │
└─────────────────────────────────────────────────────┘
```

### 4. Products Tab (`screens/products/products_tab.dart`)
```
┌──────────────────────────────────────────────────────┐
│  PRODUCTS                                            │
│  [ADD PRODUCT]          [Search: __________]         │
│                                                      │
│  ┌─── PLUTO GRID TABLE ───────────────────────────┐ │
│  │ IMG │ NAME │ PRICE │ TYPE │ AVAILABLE │ ACTION │ │
│  ├─────┼──────┼───────┼──────┼───────────┼────────┤ │
│  │ img │ Spa  │ 100   │Main  │  [●] ON   │ [EDIT] │ │
│  │ img │ Pizza│ 150   │Main  │  [○] OFF  │ [EDIT] │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

### 5. Orders Tab (`screens/orders/orders_tab.dart`)
```
┌──────────────────────────────────────────────────────┐
│  ORDERS                                              │
│  [Filter: All ▼]   [Search: __________]              │
│                                                      │
│  ┌─── DATA TABLE ────────────────────────────────┐  │
│  │ INVOICE │ TYPE          │ STATUS │ TOTAL│DATE │  │
│  ├─────────┼───────────────┼────────┼──────┼─────┤  │
│  │ #00001  │ take out      │ BILLED │ 500  │12/30│  │
│  │ #00002  │ dine in-tab 1 │ ACTIVE │ 700  │12/30│  │
│  └───────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
  ↑ Click row to view invoice
```

### 6. Settings Tab (`screens/settings/settings_tab.dart`)
```
┌──────────────────────────────────────┐
│  SETTINGS                            │
│                                      │
│  Number of Tables:                   │
│  [__10__]                            │
│                                      │
│  Product Types:                      │
│  [SHOW LIST]                         │
│                                      │
│               [SAVE SETTINGS]        │
└──────────────────────────────────────┘
```

### 7. Profile Tab (`screens/profile/profile_tab.dart`)
```
┌──────────────────────────────────────┐
│  PROFILE                             │
│                                      │
│  ┌────────┐                          │
│  │  [👤]  │                          │
│  └────────┘                          │
│                                      │
│  Username: john_doe                  │
│  Role: Admin                         │
│                                      │
│                     [LOGOUT]         │
└──────────────────────────────────────┘
```

---

## DIALOGS/WIDGETS

### 1. Menu Dialog (`widgets/menu_dialog.dart`)
- Grouped products by ProductType
- Search functionality
- Quantity controls (-, 0, +)
- Click price to edit (only for this order)
- [PROCEED] button

### 2. Invoice Dialog (`widgets/invoice_dialog.dart`)
- Invoice number header
- Scrollable items list (QTY, PRODUCT NAME, PRICE)
- Total at bottom
- [BILL OUT] button (only if status = ACTIVE)

### 3. Joiners Dialog (`widgets/joiners_dialog.dart`)
- Text input for joiner name
- [MENU] button → opens Menu Dialog
- [TABLE X JOINERS LIST] button → opens Joiners List Dialog
- [DONE] button

### 4. Joiners List Dialog (`widgets/joiners_list_dialog.dart`)
- List of joiners with status
- [VIEW INVOICE] button per joiner
- Opens Invoice Dialog when clicked

### 5. Product Type Dialog (`widgets/product_type_dialog.dart`)
- List of product types
- [EDIT] and [DELETE] per type
- [ADD] button at bottom

### 6. Product Form Dialog (`widgets/product_form_dialog.dart`)
- Form for add/edit product
- Fields: Name, Price, Type (dropdown), Image URL, Available toggle
- [SAVE] and [CANCEL] buttons

### 7. Table Card Widget (`widgets/table_card.dart`)
- Display table number
- Color based on status (GREEN/RED)
- Conditional buttons (MENU, INVOICE, JOIN)

---

## UI/UX GUIDELINES

### Colors
```dart
class AppColors {
  static const Color tableGreen = Color(0xFF4CAF50);  // Available
  static const Color tableRed = Color(0xFFF44336);     // Occupied
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFF757575);
}
```

### Typography
- Use Material Design default fonts
- Bold for headers
- Regular for body text

### Responsiveness
- Tables grid: 2 columns on mobile, 3-4 on tablet, 5+ on desktop
- Use MediaQuery for responsive layouts
- Dialogs should be scrollable on small screens

---

## STATE MANAGEMENT APPROACH

Option 1: **Provider** (Recommended)
```dart
// Providers
- AuthProvider (current user, login/logout)
- TablesProvider (tables list, refresh)
- ProductsProvider (products list, CRUD)
- OrdersProvider (orders list, create, bill out)
- SettingsProvider (settings, update)
```

Option 2: **StatefulWidget with setState**
- Simpler for small app
- Manual state management per screen

---

## NAVIGATION FLOW

```
LoginScreen
    ↓ (on successful login)
HomeScreen (with tabs)
    ├─ TablesTab
    │   ├─ Click MENU → MenuDialog → InvoiceDialog
    │   ├─ Click INVOICE → InvoiceDialog
    │   ├─ Click JOIN → JoinersDialog
    │   └─ Click TAKE OUT → MenuDialog → InvoiceDialog
    ├─ ProductsTab
    │   ├─ Click ADD PRODUCT → ProductFormDialog
    │   └─ Click EDIT → ProductFormDialog
    ├─ OrdersTab
    │   └─ Click row → InvoiceDialog (read-only if billed)
    ├─ SettingsTab
    │   └─ Click SHOW LIST → ProductTypeDialog
    └─ ProfileTab
        └─ Click LOGOUT → LoginScreen
```

---

## ERROR HANDLING

- Show SnackBar for errors
- Show Loading indicators during API calls
- Handle network errors gracefully
- Validate forms before submission

---

## TESTING CHECKLIST

- [ ] Login with correct/incorrect credentials
- [ ] View all tables with correct colors
- [ ] Create dine-in order (table turns red)
- [ ] Create joiner order
- [ ] Bill out main customer (joiners remain, table stays red)
- [ ] Bill out joiner (table turns green if no others)
- [ ] Create takeout order
- [ ] Add/Edit/Delete product
- [ ] Toggle product availability
- [ ] Add/Edit/Delete product type
- [ ] View orders history
- [ ] Update settings (number of tables)
- [ ] Logout and login again

---

## NOTES

- Keep API base URL in constants.dart for easy configuration
- Use try-catch for all API calls
- Format currency consistently (e.g., 100.00)
- Format dates consistently (e.g., MM/DD or DD/MM based on locale)
- Test on different screen sizes
- Ensure all dialogs are dismissible
