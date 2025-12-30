# FRONTEND IMPLEMENTATION TODO LIST

## Phase 1: Project Setup
- [ ] Update `pubspec.yaml` with required dependencies
  - [ ] http
  - [ ] flutter_secure_storage
  - [ ] provider
  - [ ] pluto_grid
  - [ ] intl
- [ ] Run `flutter pub get`
- [ ] Create folder structure (models, services, screens, widgets, utils)

## Phase 2: Utilities & Constants
- [ ] Create `utils/constants.dart`
  - [ ] API base URL
  - [ ] Color constants (tableGreen, tableRed, etc.)
  - [ ] Text styles
- [ ] Create `utils/formatters.dart`
  - [ ] Currency formatter
  - [ ] Date formatter

## Phase 3: Models
- [ ] Create `models/user.dart` - User model with fromJson
- [ ] Create `models/settings.dart` - Settings model with fromJson/toJson
- [ ] Create `models/product_type.dart` - ProductType model with fromJson/toJson
- [ ] Create `models/product.dart` - Product model with fromJson/toJson
- [ ] Create `models/table.dart` - Table model with fromJson
- [ ] Create `models/order.dart` - Order and OrderItem models with fromJson/toJson

## Phase 4: Services (API Layer)
- [ ] Create `services/api_client.dart`
  - [ ] Setup base URL and headers
  - [ ] JWT token storage methods (get, save, delete)
  - [ ] HTTP methods (GET, POST, PUT, PATCH, DELETE)

- [ ] Create `services/auth_service.dart`
  - [ ] login()
  - [ ] logout()
  - [ ] getCurrentUser()

- [ ] Create `services/settings_service.dart`
  - [ ] getSettings()
  - [ ] updateSettings()

- [ ] Create `services/product_type_service.dart`
  - [ ] getAllProductTypes()
  - [ ] createProductType()
  - [ ] updateProductType()
  - [ ] deleteProductType()

- [ ] Create `services/product_service.dart`
  - [ ] getAllProducts()
  - [ ] getMenuProducts()
  - [ ] getProductById()
  - [ ] createProduct()
  - [ ] updateProduct()
  - [ ] toggleAvailability()
  - [ ] deleteProduct()

- [ ] Create `services/table_service.dart`
  - [ ] getAllTables()
  - [ ] getTableDetails()
  - [ ] getTableJoiners()

- [ ] Create `services/order_service.dart`
  - [ ] getAllOrders()
  - [ ] getOrderById()
  - [ ] createDineInOrder()
  - [ ] createTakeoutOrder()
  - [ ] createJoinerOrder()
  - [ ] billOutOrder()

## Phase 5: State Management (Provider)
- [ ] Create `providers/auth_provider.dart`
  - [ ] Current user state
  - [ ] Login method
  - [ ] Logout method
  - [ ] Check authentication status

- [ ] Create `providers/tables_provider.dart`
  - [ ] Tables list state
  - [ ] Refresh tables method
  - [ ] Get table by number

- [ ] Create `providers/products_provider.dart`
  - [ ] Products list state
  - [ ] CRUD methods
  - [ ] Toggle availability method

- [ ] Create `providers/orders_provider.dart`
  - [ ] Orders list state
  - [ ] Create order methods
  - [ ] Bill out method
  - [ ] Filter orders

- [ ] Create `providers/settings_provider.dart`
  - [ ] Settings state
  - [ ] Update settings method

## Phase 6: Reusable Widgets
- [ ] Create `widgets/table_card.dart`
  - [ ] Display table number
  - [ ] Color based on status (GREEN/RED)
  - [ ] Conditional buttons (MENU, INVOICE, JOIN)

- [ ] Create `widgets/menu_dialog.dart`
  - [ ] Fetch menu products
  - [ ] Group products by type
  - [ ] Search functionality
  - [ ] Product item with quantity controls
  - [ ] Price editing
  - [ ] PROCEED button

- [ ] Create `widgets/invoice_dialog.dart`
  - [ ] Display invoice number
  - [ ] Scrollable items list
  - [ ] Total calculation
  - [ ] BILL OUT button (conditional)

- [ ] Create `widgets/joiners_dialog.dart`
  - [ ] Joiner name input
  - [ ] MENU button
  - [ ] TABLE X JOINERS LIST button
  - [ ] DONE button

- [ ] Create `widgets/joiners_list_dialog.dart`
  - [ ] List of joiners with status
  - [ ] VIEW INVOICE button per joiner

- [ ] Create `widgets/product_type_dialog.dart`
  - [ ] List of product types
  - [ ] EDIT and DELETE buttons
  - [ ] ADD button
  - [ ] Add/Edit form

- [ ] Create `widgets/product_form_dialog.dart`
  - [ ] Form fields (name, price, type, image, available)
  - [ ] Validation
  - [ ] SAVE and CANCEL buttons

- [ ] Create `widgets/product_item_card.dart`
  - [ ] Product display for menu
  - [ ] Quantity controls
  - [ ] Price display/edit

## Phase 7: Screens - Authentication
- [ ] Create `screens/auth/login_screen.dart`
  - [ ] Username and password fields
  - [ ] Login button
  - [ ] Handle login logic
  - [ ] Navigate to home on success
  - [ ] Show error messages

## Phase 8: Screens - Main Navigation
- [ ] Create `screens/home/home_screen.dart`
  - [ ] Bottom navigation or tab bar
  - [ ] 5 tabs: Tables, Products, Orders, Settings, Profile
  - [ ] Tab switching logic

## Phase 9: Screens - Tables Tab
- [ ] Create `screens/tables/tables_tab.dart`
  - [ ] Fetch tables from API
  - [ ] Display tables in responsive grid
  - [ ] TAKE OUT button
  - [ ] Handle MENU button click
  - [ ] Handle INVOICE button click
  - [ ] Handle JOIN button click
  - [ ] Handle TAKE OUT button click
  - [ ] Refresh after order creation/bill out

## Phase 10: Screens - Products Tab
- [ ] Create `screens/products/products_tab.dart`
  - [ ] Display products in PlutoGrid
  - [ ] ADD PRODUCT button
  - [ ] Search functionality
  - [ ] EDIT button per product
  - [ ] Availability toggle
  - [ ] Soft delete (hide deleted products)

## Phase 11: Screens - Orders Tab
- [ ] Create `screens/orders/orders_tab.dart`
  - [ ] Display orders in data table
  - [ ] Filter dropdown (All, ACTIVE, BILLED_OUT)
  - [ ] Search functionality
  - [ ] Click row to view invoice
  - [ ] Show invoice dialog (read-only if billed)

## Phase 12: Screens - Settings Tab
- [ ] Create `screens/settings/settings_tab.dart`
  - [ ] Number of tables input
  - [ ] SHOW LIST button for product types
  - [ ] SAVE SETTINGS button
  - [ ] Handle product type dialog

## Phase 13: Screens - Profile Tab
- [ ] Create `screens/profile/profile_tab.dart`
  - [ ] Display user avatar
  - [ ] Display username and role
  - [ ] LOGOUT button
  - [ ] Handle logout logic

## Phase 14: Main App
- [ ] Update `main.dart`
  - [ ] Setup MultiProvider
  - [ ] Setup theme
  - [ ] Setup initial route (LoginScreen)
  - [ ] Check authentication on startup

## Phase 15: Integration & Business Logic
- [ ] Implement menu dialog workflow
  - [ ] Select products
  - [ ] Edit prices per order
  - [ ] Calculate total
  - [ ] Return selected items

- [ ] Implement dine-in flow
  - [ ] Show menu → select products → create order → table turns red

- [ ] Implement joiner flow
  - [ ] Enter name → show menu → select products → create joiner order

- [ ] Implement takeout flow
  - [ ] Show menu → select products → show invoice → bill out

- [ ] Implement bill out flow
  - [ ] Show invoice → bill out → update table status

- [ ] Implement joiners list flow
  - [ ] Show joiners → view invoice → bill out individual joiner

## Phase 16: UI Polish
- [ ] Add loading indicators
- [ ] Add error handling with SnackBars
- [ ] Add confirmation dialogs for delete actions
- [ ] Add form validation
- [ ] Ensure responsive design
- [ ] Add animations (optional)

## Phase 17: Testing
- [ ] Test login/logout flow
- [ ] Test all table states (GREEN/RED logic)
- [ ] Test dine-in order creation
- [ ] Test joiner order creation
- [ ] Test takeout order creation
- [ ] Test bill out functionality
- [ ] Test main customer bill out with joiners remaining
- [ ] Test joiner bill out
- [ ] Test product CRUD
- [ ] Test product type CRUD
- [ ] Test settings update
- [ ] Test orders filtering and search
- [ ] Test on different screen sizes

## Phase 18: Documentation & Cleanup
- [ ] Add code comments
- [ ] Update FRONTEND.md if needed
- [ ] Remove debug prints
- [ ] Optimize imports
- [ ] Test on Android/iOS/Web

---

## Current Status: Not Started
## Next Task: Update pubspec.yaml and create folder structure
