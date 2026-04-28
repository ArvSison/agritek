<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
}

$body = read_json_body();
$username = trim((string)($body['username'] ?? ''));
$password = (string)($body['password'] ?? '');

if ($username === '' || $password === '') {
  json_response(400, ['ok' => false, 'error' => 'username and password required']);
}

try {
  $stmt = $pdo->prepare('
    SELECT id, username, email, password_hash, role, status,
           display_name, address, phone, gender, birth_date, avatar_url
    FROM users WHERE username = :username LIMIT 1
  ');
  $stmt->execute([':username' => $username]);
  $user = $stmt->fetch();

  if (!$user || !password_verify($password, (string)$user['password_hash'])) {
    json_response(401, ['ok' => false, 'error' => 'Invalid credentials']);
  }

  $status = (string)($user['status'] ?? 'active');
  if ($status === 'pending') {
    json_response(403, ['ok' => false, 'error' => 'Account pending admin approval']);
  }
  if ($status === 'rejected') {
    json_response(403, ['ok' => false, 'error' => 'Account rejected']);
  }

  $token = create_session($pdo, (int)$user['id']);

  json_response(200, [
    'ok' => true,
    'token' => $token,
    'user' => [
      'id' => (int)$user['id'],
      'username' => $user['username'],
      'email' => $user['email'],
      'role' => $user['role'],
      'status' => $status,
      'display_name' => $user['display_name'] ?? null,
      'address' => $user['address'] ?? null,
      'phone' => $user['phone'] ?? null,
      'gender' => $user['gender'] ?? null,
      'birth_date' => isset($user['birth_date']) && $user['birth_date'] !== null && $user['birth_date'] !== ''
        ? substr((string) $user['birth_date'], 0, 10)
        : null,
      'avatar_url' => $user['avatar_url'] ?? null,
    ],
  ]);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'Login failed']);
}
