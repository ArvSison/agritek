<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

require_admin_access($pdo);
$method = $_SERVER['REQUEST_METHOD'];

try {
  if ($method === 'GET') {
    $stmt = $pdo->query('
      SELECT p.*, u.username AS farmer_username
      FROM products p
      LEFT JOIN users u ON u.id = p.farmer_id
      ORDER BY p.id DESC
    ');
    json_response(200, ['ok' => true, 'products' => $stmt->fetchAll()]);
  }

  if ($method === 'PATCH') {
    $id = (int)($_GET['id'] ?? 0);
    $action = (string)($_GET['action'] ?? '');
    if ($id <= 0 || !in_array($action, ['approve', 'reject', 'delete'], true)) {
      json_response(400, ['ok' => false, 'error' => 'id and action approve|reject|delete required']);
    }
    if ($action === 'delete') {
      $pdo->prepare('DELETE FROM products WHERE id=:id')->execute([':id' => $id]);
      json_response(200, ['ok' => true]);
    }
    $status = $action === 'approve' ? 'active' : 'rejected';
    $pdo->prepare('UPDATE products SET status=:s WHERE id=:id')->execute([':s' => $status, ':id' => $id]);

    $stmt = $pdo->prepare('SELECT farmer_id, name FROM products WHERE id=:id');
    $stmt->execute([':id' => $id]);
    $p = $stmt->fetch();
    if ($p && $p['farmer_id']) {
      notify_user($pdo, (int)$p['farmer_id'], 'product_' . $status, 'Product update', 'Your product "' . $p['name'] . '" is ' . $status, ['product_id' => $id]);
    }
    json_response(200, ['ok' => true]);
  }

  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'admin_products failed']);
}
