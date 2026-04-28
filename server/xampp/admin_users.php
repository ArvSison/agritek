<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

require_admin_access($pdo);
$method = $_SERVER['REQUEST_METHOD'];

try {
  if ($method === 'GET') {
    $rows = $pdo->query("SELECT id, username, email, role, status, created_at FROM users ORDER BY id DESC")->fetchAll();
    json_response(200, ['ok' => true, 'users' => $rows]);
  }

  if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    $action = (string)($_GET['action'] ?? '');
    if ($id <= 0 || !in_array($action, ['approve', 'reject'], true)) {
      json_response(400, ['ok' => false, 'error' => 'id and action approve|reject required']);
    }
    $status = $action === 'approve' ? 'active' : 'rejected';
    $stmt = $pdo->prepare('UPDATE users SET status = :s WHERE id = :id');
    $stmt->execute([':s' => $status, ':id' => $id]);
    notify_user($pdo, $id, 'account_' . $status, 'Account update', 'Your account is now ' . $status, ['user_id' => $id]);
    json_response(200, ['ok' => true]);
  }

  if ($method === 'PUT') {
    $body = read_json_body();
    $id = (int)($body['id'] ?? 0);
    if ($id <= 0) json_response(400, ['ok' => false, 'error' => 'id required']);
    $username = trim((string)($body['username'] ?? ''));
    $email = trim((string)($body['email'] ?? ''));
    $role = (string)($body['role'] ?? '');
    if ($username === '' || $email === '' || !in_array($role, ['buyer', 'farmer', 'admin'], true)) {
      json_response(400, ['ok' => false, 'error' => 'username, email, role required']);
    }
    $stmt = $pdo->prepare('UPDATE users SET username=:u, email=:e, role=:r WHERE id=:id');
    $stmt->execute([':u' => $username, ':e' => $email, ':r' => $role, ':id' => $id]);
    json_response(200, ['ok' => true]);
  }

  if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if ($id <= 0) json_response(400, ['ok' => false, 'error' => 'id required']);
    $stmt = $pdo->prepare('DELETE FROM users WHERE id = :id');
    $stmt->execute([':id' => $id]);
    json_response(200, ['ok' => true]);
  }

  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'admin_users failed']);
}
