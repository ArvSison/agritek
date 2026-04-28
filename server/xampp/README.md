## Agritek XAMPP backend (PHP + MySQL)

Copy this folder into your Apache web root (for example `C:\xampp\htdocs\LibraryMonitoring\agritek_api\` or `C:\xampp\htdocs\agritek_api\`).

### Setup order

1. Start **Apache** + **MySQL** in XAMPP.
2. In phpMyAdmin, create database **`agritek`** and import **`schema.sql`** (base tables).
3. Open **`migrate_v2.php`** once in the browser (adds sessions, orders, cart, notifications, user status, product moderation, etc.).
   - Example: `http://localhost/agritek_api/migrate_v2.php`
4. Open **`seed.php`** (demo users + **admin PIN hash** + links products to `farmer1`).
   - Example: `http://localhost/agritek_api/seed.php`
5. If MySQL credentials differ from defaults, edit **`config.php`**.

### Auth

- `POST /login.php` returns `{ ok, token, user }`. Flutter stores `token` and sends `Authorization: Bearer <token>`.
- Admin UI uses `POST /admin_verify_pin.php` → `{ admin_gate_token }` on header **`X-Admin-Gate`** for admin-only routes.

### Main endpoints

| File | Purpose |
|------|---------|
| `health.php` | Health check |
| `register.php` | Sign up buyer/farmer (`pending` until admin approves) |
| `login.php` | Login + session token |
| `products.php` | Public active products |
| `farmer_my_products.php` | Farmer’s own products (all statuses) |
| `farmer_products.php` | Farmer submits new product (`pending`) |
| `cart.php` | Buyer cart (GET/POST/DELETE) |
| `orders.php` | Buyer/farmer orders + checkout + status actions |
| `admin_orders.php` | Admin lists / sets any order status (requires gate) |
| `notifications.php` | Logged-in user notifications |
| `messages.php` | Direct messages |
| `follows.php` | Follow / unfollow |
| `users_discovery.php` | Buyers list farmers (and vice versa) |
| `admin_verify_pin.php` | 4-digit PIN → admin gate token |
| `admin_users.php` | List / approve / reject / edit / delete users (gate) |
| `admin_products.php` | List / approve / reject / delete products (gate) |
| `admin_notifications.php` | Admin-wide notifications feed (gate) |
| `admin_messages.php` | Admin sends message as first admin user (gate) |

### Demo accounts (after `seed.php`)

- `buyer1` / `password123`
- `farmer1` / `password123`
- `admin1` / `password123`
- Admin PIN (for `admin_verify_pin.php`): **`9999`**

### Notes

- Run **`migrate_v2.php` before `seed.php`** if `seed.php` errors on unknown columns.
- For a phone on Wi‑Fi, use your PC LAN IP instead of `localhost` in Flutter `api_config.dart`.
