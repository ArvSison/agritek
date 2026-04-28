<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$auth = require_login($pdo);
$uid = (int) $auth['id'];

function fetch_user_profile(PDO $pdo, int $uid): ?array {
  $stmt = $pdo->prepare('
    SELECT id, username, email, role, status, display_name, address, phone, gender, birth_date, avatar_url
    FROM users WHERE id = :id LIMIT 1
  ');
  $stmt->execute([':id' => $uid]);
  $row = $stmt->fetch();
  return $row ?: null;
}

function user_profile_payload(array $row): array {
  $bd = $row['birth_date'] ?? null;
  $birthOut = null;
  if ($bd !== null && $bd !== '') {
    $birthOut = is_string($bd) ? substr($bd, 0, 10) : substr((string) $bd, 0, 10);
  }
  return [
    'id' => (int) $row['id'],
    'username' => $row['username'],
    'email' => $row['email'],
    'role' => $row['role'],
    'status' => $row['status'],
    'display_name' => $row['display_name'] ?? null,
    'address' => $row['address'] ?? null,
    'phone' => $row['phone'] ?? null,
    'gender' => $row['gender'] ?? null,
    'birth_date' => $birthOut,
    'avatar_url' => $row['avatar_url'] ?? null,
  ];
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
  $row = fetch_user_profile($pdo, $uid);
  if (!$row) {
    json_response(404, ['ok' => false, 'error' => 'User not found']);
  }
  json_response(200, ['ok' => true, 'user' => user_profile_payload($row)]);
}

if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') {
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
}

$body = read_json_body();
$updates = [];
$params = [':id' => $uid];

if (array_key_exists('username', $body)) {
  $nu = trim((string) $body['username']);
  if ($nu === '') {
    json_response(400, ['ok' => false, 'error' => 'username cannot be empty']);
  }
  $chk = $pdo->prepare('SELECT id FROM users WHERE username = :u AND id <> :id LIMIT 1');
  $chk->execute([':u' => $nu, ':id' => $uid]);
  if ($chk->fetch()) {
    json_response(400, ['ok' => false, 'error' => 'Username already taken']);
  }
  $updates[] = 'username = :username';
  $params[':username'] = $nu;
}

if (array_key_exists('email', $body)) {
  $em = trim((string) $body['email']);
  if ($em === '') {
    json_response(400, ['ok' => false, 'error' => 'email cannot be empty']);
  }
  $chk = $pdo->prepare('SELECT id FROM users WHERE email = :e AND id <> :id LIMIT 1');
  $chk->execute([':e' => $em, ':id' => $uid]);
  if ($chk->fetch()) {
    json_response(400, ['ok' => false, 'error' => 'Email already in use']);
  }
  $updates[] = 'email = :email';
  $params[':email'] = $em;
}

if (array_key_exists('display_name', $body)) {
  $dn = trim((string) $body['display_name']);
  $updates[] = 'display_name = :display_name';
  $params[':display_name'] = $dn === '' ? null : mb_substr($dn, 0, 120);
}

if (array_key_exists('address', $body)) {
  $ad = trim((string) $body['address']);
  $updates[] = 'address = :address';
  $params[':address'] = $ad === '' ? null : mb_substr($ad, 0, 255);
}

if (array_key_exists('phone', $body)) {
  $ph = trim((string) $body['phone']);
  $updates[] = 'phone = :phone';
  $params[':phone'] = $ph === '' ? null : mb_substr($ph, 0, 40);
}

if (array_key_exists('gender', $body)) {
  $g = trim((string) $body['gender']);
  $updates[] = 'gender = :gender';
  $params[':gender'] = $g === '' ? null : mb_substr($g, 0, 20);
}

if (array_key_exists('birth_date', $body)) {
  $v = $body['birth_date'];
  if ($v === null || $v === '') {
    $updates[] = 'birth_date = NULL';
  } else {
    $vs = trim((string) $v);
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $vs)) {
      json_response(400, ['ok' => false, 'error' => 'birth_date must be YYYY-MM-DD']);
    }
    $updates[] = 'birth_date = :birth_date';
    $params[':birth_date'] = $vs;
  }
}

if (array_key_exists('avatar_url', $body)) {
  $au = trim((string) $body['avatar_url']);
  $updates[] = 'avatar_url = :avatar_url';
  $params[':avatar_url'] = $au === '' ? null : mb_substr($au, 0, 2048);
}

if ($updates === []) {
  $row = fetch_user_profile($pdo, $uid);
  if (!$row) {
    json_response(404, ['ok' => false, 'error' => 'User not found']);
  }
  json_response(200, ['ok' => true, 'user' => user_profile_payload($row)]);
}

$sql = 'UPDATE users SET ' . implode(', ', $updates) . ' WHERE id = :id';
try {
  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'Could not update profile']);
}

$row = fetch_user_profile($pdo, $uid);
if (!$row) {
  json_response(500, ['ok' => false, 'error' => 'Profile update failed']);
}
json_response(200, ['ok' => true, 'user' => user_profile_payload($row)]);
