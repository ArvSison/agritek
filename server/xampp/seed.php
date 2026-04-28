<?php
require_once __DIR__ . '/config.php';

// Run after migrate_v2.php (adds sessions, app_settings, status columns, etc.)

$password = 'password123';
$hash = password_hash($password, PASSWORD_DEFAULT);
$pinHash = password_hash('9999', PASSWORD_DEFAULT);

try {
  $as = $pdo->prepare("INSERT INTO app_settings (k, v) VALUES ('admin_pin_hash', :v)
    ON DUPLICATE KEY UPDATE v = VALUES(v)");
  $as->execute([':v' => $pinHash]);

  $stmt = $pdo->prepare('
    INSERT INTO users (username, email, password_hash, role, status)
    VALUES (:username, :email, :password_hash, :role, \'active\')
    ON DUPLICATE KEY UPDATE
      email = VALUES(email),
      role = VALUES(role),
      password_hash = VALUES(password_hash),
      status = \'active\'
  ');

  $users = [
    ['username' => 'buyer1',  'email' => 'buyer1@example.com',  'role' => 'buyer'],
    ['username' => 'farmer1', 'email' => 'farmer1@example.com', 'role' => 'farmer'],
    ['username' => 'admin1',  'email' => 'admin1@example.com',  'role' => 'admin'],
  ];

  foreach ($users as $u) {
    $stmt->execute([
      ':username' => $u['username'],
      ':email' => $u['email'],
      ':role' => $u['role'],
      ':password_hash' => $hash,
    ]);
  }

  $pdo->exec("UPDATE products p JOIN users u ON u.username='farmer1' SET p.farmer_id=u.id WHERE p.farmer_id IS NULL OR p.farmer_id=0");
  $pdo->exec("UPDATE products SET status='active' WHERE status IS NULL OR status=''");

  json_response(200, [
    'ok' => true,
    'seeded' => count($users),
    'password' => $password,
    'admin_pin' => '9999',
    'hint' => 'Run migrate_v2.php first if this errors on unknown column.',
  ]);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'Seed failed (run migrate_v2.php first?)']);
}
