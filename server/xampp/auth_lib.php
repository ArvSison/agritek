<?php
declare(strict_types=1);

/** Raw Authorization header (Apache often omits HTTP_AUTHORIZATION). */
function raw_authorization_header(): string {
  $candidates = [
    $_SERVER['HTTP_AUTHORIZATION'] ?? '',
    $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '',
  ];
  foreach ($candidates as $h) {
    if (is_string($h) && trim($h) !== '') {
      return trim($h);
    }
  }
  if (function_exists('getallheaders')) {
    $headers = getallheaders();
    if (is_array($headers)) {
      foreach ($headers as $name => $value) {
        if (strcasecmp((string) $name, 'Authorization') === 0 && is_string($value) && trim($value) !== '') {
          return trim($value);
        }
      }
    }
  }
  if (function_exists('apache_request_headers')) {
    $headers = apache_request_headers();
    if (is_array($headers)) {
      foreach ($headers as $name => $value) {
        if (strcasecmp((string) $name, 'Authorization') === 0 && is_string($value) && trim($value) !== '') {
          return trim($value);
        }
      }
    }
  }
  return '';
}

function bearer_token(): ?string {
  $h = raw_authorization_header();
  if ($h === '') {
    return null;
  }
  if (stripos($h, 'Bearer ') === 0) {
    return trim(substr($h, 7));
  }
  return null;
}

function admin_gate_token(): ?string {
  $g = $_SERVER['HTTP_X_ADMIN_GATE'] ?? '';
  if (is_string($g) && trim($g) !== '') {
    return trim($g);
  }
  if (function_exists('getallheaders')) {
    $headers = getallheaders();
    if (is_array($headers)) {
      foreach ($headers as $name => $value) {
        if (strcasecmp((string) $name, 'X-Admin-Gate') === 0 && is_string($value) && trim($value) !== '') {
          return trim($value);
        }
      }
    }
  }
  return null;
}

function require_login(PDO $pdo): array {
  $token = bearer_token();
  if ($token === null || $token === '') {
    json_response(401, ['ok' => false, 'error' => 'Missing bearer token']);
  }
  $hash = hash('sha256', $token);
  try {
    $stmt = $pdo->prepare('
      SELECT u.id, u.username, u.email, u.role, u.status
      FROM sessions s
      JOIN users u ON u.id = s.user_id
      WHERE s.token_hash = :h
      LIMIT 1
    ');
    $stmt->execute([':h' => $hash]);
    $u = $stmt->fetch();
    if (!$u) {
      json_response(401, ['ok' => false, 'error' => 'Invalid session']);
    }
    if (($u['status'] ?? '') !== 'active') {
      json_response(403, ['ok' => false, 'error' => 'Account not active']);
    }
    return $u;
  } catch (Throwable $e) {
    json_response(500, ['ok' => false, 'error' => 'Auth failed']);
  }
}

function require_roles(PDO $pdo, array $roles): array {
  $u = require_login($pdo);
  if (!in_array($u['role'], $roles, true)) {
    json_response(403, ['ok' => false, 'error' => 'Forbidden']);
  }
  return $u;
}

function require_admin_gate(PDO $pdo): void {
  $token = admin_gate_token();
  if ($token === null || $token === '') {
    json_response(401, ['ok' => false, 'error' => 'Missing X-Admin-Gate token']);
  }
  $hash = hash('sha256', $token);
  try {
    $stmt = $pdo->prepare('SELECT id, expires_at FROM admin_sessions WHERE token_hash = :h LIMIT 1');
    $stmt->execute([':h' => $hash]);
    $row = $stmt->fetch();
    if (!$row) {
      json_response(401, ['ok' => false, 'error' => 'Invalid admin gate']);
    }
    if (strtotime((string)$row['expires_at']) < time()) {
      json_response(401, ['ok' => false, 'error' => 'Admin gate expired']);
    }
  } catch (Throwable $e) {
    json_response(500, ['ok' => false, 'error' => 'Admin gate check failed']);
  }
}

/** Admin API: either valid PIN gate **or** logged-in user with role `admin`. */
function require_admin_access(PDO $pdo): void {
  $gate = admin_gate_token();
  if ($gate !== null && $gate !== '') {
    require_admin_gate($pdo);
    return;
  }
  $u = require_login($pdo);
  if (($u['role'] ?? '') !== 'admin') {
    json_response(403, ['ok' => false, 'error' => 'Admin only']);
  }
}

function create_session(PDO $pdo, int $userId): string {
  $token = bin2hex(random_bytes(32));
  $hash = hash('sha256', $token);
  $expires = (new DateTimeImmutable('+30 days'))->format('Y-m-d H:i:s');
  $stmt = $pdo->prepare('INSERT INTO sessions (user_id, token_hash, expires_at) VALUES (:uid, :th, :ex)');
  $stmt->execute([':uid' => $userId, ':th' => $hash, ':ex' => $expires]);
  return $token;
}

function notify_user(PDO $pdo, int $userId, string $type, string $title, string $body, ?array $data = null): void {
  $dj = $data ? json_encode($data, JSON_UNESCAPED_SLASHES) : null;
  $stmt = $pdo->prepare('INSERT INTO notifications (user_id, type, title, body, data_json) VALUES (:uid, :t, :ti, :b, :d)');
  $stmt->execute([':uid' => $userId, ':t' => $type, ':ti' => $title, ':b' => $body, ':d' => $dj]);
}

function notify_all_admins(PDO $pdo, string $type, string $title, string $body, ?array $data = null): void {
  $admins = $pdo->query("SELECT id FROM users WHERE role='admin' AND status='active'")->fetchAll();
  foreach ($admins as $a) {
    notify_user($pdo, (int)$a['id'], $type, $title, $body, $data);
  }
}

function farmer_ids_for_order(PDO $pdo, int $orderId): array {
  $stmt = $pdo->prepare('
    SELECT DISTINCT p.farmer_id
    FROM order_items oi
    JOIN products p ON p.id = oi.product_id
    WHERE oi.order_id = :oid AND p.farmer_id IS NOT NULL
  ');
  $stmt->execute([':oid' => $orderId]);
  $rows = $stmt->fetchAll();
  $out = [];
  foreach ($rows as $r) {
    $out[] = (int)$r['farmer_id'];
  }
  return $out;
}
