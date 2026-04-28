<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';

// Run once in browser: http://localhost/.../migrate_v2.php
// Adds tables/columns for orders, cart, notifications, sessions, etc.

function try_exec(PDO $pdo, string $sql): string {
  try {
    $pdo->exec($sql);
    return "OK: $sql";
  } catch (Throwable $e) {
    return "SKIP/FAIL: $sql :: " . $e->getMessage();
  }
}

$log = [];

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS app_settings (
  k VARCHAR(64) NOT NULL,
  v TEXT NULL,
  PRIMARY KEY (k)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS sessions (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_sessions_token (token_hash),
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS admin_sessions (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_admin_sessions_token (token_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$log[] = try_exec($pdo, "ALTER TABLE users ADD COLUMN status ENUM('pending','active','rejected') NOT NULL DEFAULT 'active'");
$log[] = try_exec($pdo, "ALTER TABLE products ADD COLUMN farmer_id INT UNSIGNED NULL");
$log[] = try_exec($pdo, "ALTER TABLE products ADD COLUMN status ENUM('pending','active','rejected') NOT NULL DEFAULT 'active'");
$log[] = try_exec($pdo, "ALTER TABLE products ADD CONSTRAINT fk_products_farmer FOREIGN KEY (farmer_id) REFERENCES users(id) ON DELETE SET NULL");

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS cart_items (
  user_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  qty INT UNSIGNED NOT NULL DEFAULT 1,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, product_id),
  CONSTRAINT fk_cart_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS orders (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  buyer_id INT UNSIGNED NOT NULL,
  status ENUM('to_pay','to_ship','to_receive','completed') NOT NULL DEFAULT 'to_pay',
  total_php DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_orders_buyer (buyer_id),
  CONSTRAINT fk_orders_buyer FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS order_items (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  qty INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price_php DECIMAL(12,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_order_items_order (order_id),
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS notifications (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  type VARCHAR(64) NOT NULL,
  title VARCHAR(160) NOT NULL,
  body TEXT NULL,
  data_json TEXT NULL,
  read_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notif_user (user_id),
  CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS messages (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  from_user_id INT UNSIGNED NOT NULL,
  to_user_id INT UNSIGNED NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_msg_pair (from_user_id, to_user_id),
  CONSTRAINT fk_msg_from FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_msg_to FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

$log[] = try_exec($pdo, "CREATE TABLE IF NOT EXISTS follows (
  follower_id INT UNSIGNED NOT NULL,
  following_id INT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (follower_id, following_id),
  CONSTRAINT fk_follow_follower FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_follow_following FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

// Backfill products + users for existing installs
$log[] = try_exec($pdo, "UPDATE users SET status='active' WHERE status IS NULL OR status=''");
$log[] = try_exec($pdo, "UPDATE products SET status='active' WHERE status IS NULL OR status=''");
$log[] = try_exec($pdo, "UPDATE products p JOIN users u ON u.username='farmer1' SET p.farmer_id=u.id WHERE p.farmer_id IS NULL");

// Profile fields (run migrate after deploy; duplicates are skipped)
$log[] = try_exec($pdo, "ALTER TABLE users ADD COLUMN display_name VARCHAR(120) NULL");
$log[] = try_exec($pdo, "ALTER TABLE users ADD COLUMN address VARCHAR(255) NULL");
$log[] = try_exec($pdo, "ALTER TABLE users ADD COLUMN phone VARCHAR(40) NULL");
$log[] = try_exec($pdo, "ALTER TABLE users ADD COLUMN gender VARCHAR(20) NULL");
$log[] = try_exec($pdo, "ALTER TABLE users ADD COLUMN birth_date DATE NULL");
$log[] = try_exec($pdo, "ALTER TABLE users ADD COLUMN avatar_url TEXT NULL");

json_response(200, ['ok' => true, 'migrate_log' => $log]);
