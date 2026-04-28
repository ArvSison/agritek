<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
}

$body = read_json_body();
$pin = (string)($body['pin'] ?? '');
if (strlen($pin) !== 4 || !ctype_digit($pin)) {
  json_response(400, ['ok' => false, 'error' => 'PIN must be 4 digits']);
}

try {
  $stmt = $pdo->prepare('SELECT v FROM app_settings WHERE k = :k LIMIT 1');
  $stmt->execute([':k' => 'admin_pin_hash']);
  $row = $stmt->fetch();
  if (!$row || !password_verify($pin, (string)$row['v'])) {
    json_response(401, ['ok' => false, 'error' => 'Wrong PIN']);
  }

  $token = bin2hex(random_bytes(24));
  $hash = hash('sha256', $token);
  $expires = (new DateTimeImmutable('+8 hours'))->format('Y-m-d H:i:s');
  $ins = $pdo->prepare('INSERT INTO admin_sessions (token_hash, expires_at) VALUES (:h,:ex)');
  $ins->execute([':h' => $hash, ':ex' => $expires]);

  json_response(200, ['ok' => true, 'admin_gate_token' => $token]);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'PIN verify failed']);
}
