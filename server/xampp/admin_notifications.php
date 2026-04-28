<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

require_admin_access($pdo);
$method = $_SERVER['REQUEST_METHOD'];

try {
  if ($method === 'GET') {
    $stmt = $pdo->query('
      SELECT n.*
      FROM notifications n
      WHERE n.user_id IN (SELECT id FROM users WHERE role = \'admin\' AND status = \'active\')
      ORDER BY n.id DESC
      LIMIT 200
    ');
    json_response(200, ['ok' => true, 'notifications' => $stmt->fetchAll()]);
  }
  if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    if ($id <= 0) json_response(400, ['ok' => false, 'error' => 'id required']);
    $pdo->prepare('UPDATE notifications SET read_at = NOW() WHERE id = :id')->execute([':id' => $id]);
    json_response(200, ['ok' => true]);
  }
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'admin_notifications failed']);
}
