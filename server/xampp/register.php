<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
}

$body = read_json_body();
$username = trim((string)($body['username'] ?? ''));
$email = trim((string)($body['email'] ?? ''));
$password = (string)($body['password'] ?? '');
$role = (string)($body['role'] ?? 'buyer');

if ($username === '' || $email === '' || $password === '') {
  json_response(400, ['ok' => false, 'error' => 'username, email, password required']);
}
if (!in_array($role, ['buyer', 'farmer'], true)) {
  json_response(400, ['ok' => false, 'error' => 'role must be buyer or farmer']);
}

try {
  $hash = password_hash($password, PASSWORD_DEFAULT);
  $stmt = $pdo->prepare('INSERT INTO users (username, email, password_hash, role, status) VALUES (:u,:e,:p,:r, \'pending\')');
  $stmt->execute([':u' => $username, ':e' => $email, ':p' => $hash, ':r' => $role]);
  $id = (int)$pdo->lastInsertId();

  notify_all_admins($pdo, 'user_pending', 'New user registration', "Approve {$username} ({$role})", ['user_id' => $id]);

  json_response(200, ['ok' => true, 'user_id' => $id, 'message' => 'Registered; pending admin approval']);
} catch (Throwable $e) {
  json_response(400, ['ok' => false, 'error' => 'Could not register (duplicate username/email?)']);
}
