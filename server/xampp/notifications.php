<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_login($pdo);
$uid = (int)$u['id'];
$method = $_SERVER['REQUEST_METHOD'];

try {
  if ($method === 'GET') {
    $stmt = $pdo->prepare('SELECT * FROM notifications WHERE user_id=:u ORDER BY id DESC LIMIT 100');
    $stmt->execute([':u' => $uid]);
    json_response(200, ['ok' => true, 'notifications' => $stmt->fetchAll()]);
  }
  if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if ($id <= 0) json_response(400, ['ok' => false, 'error' => 'id required']);
    $pdo->prepare('UPDATE notifications SET read_at = NOW() WHERE id=:id AND user_id=:u')->execute([':id' => $id, ':u' => $uid]);
    json_response(200, ['ok' => true]);
  }
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'notifications failed']);
}
