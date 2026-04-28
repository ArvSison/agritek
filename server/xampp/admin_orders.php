<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

require_admin_access($pdo);
$method = $_SERVER['REQUEST_METHOD'];

function order_detail(PDO $pdo, int $orderId): array {
  $o = $pdo->prepare('SELECT o.*, u.username AS buyer_username FROM orders o JOIN users u ON u.id=o.buyer_id WHERE o.id=:id');
  $o->execute([':id' => $orderId]);
  $order = $o->fetch();
  if (!$order) return [];
  $items = $pdo->prepare('SELECT oi.*, p.name FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.order_id=:id');
  $items->execute([':id' => $orderId]);
  $order['items'] = $items->fetchAll();
  return $order;
}

try {
  if ($method === 'GET') {
    $rows = $pdo->query('SELECT o.*, u.username AS buyer_username FROM orders o JOIN users u ON u.id=o.buyer_id ORDER BY o.id DESC LIMIT 200')->fetchAll();
    json_response(200, ['ok' => true, 'orders' => $rows]);
  }

  if ($method === 'PATCH') {
    $body = read_json_body();
    $id = (int)($body['id'] ?? 0);
    $status = (string)($body['status'] ?? '');
    if ($id <= 0 || !in_array($status, ['to_pay', 'to_ship', 'to_receive', 'completed'], true)) {
      json_response(400, ['ok' => false, 'error' => 'id and status required']);
    }
    $pdo->prepare('UPDATE orders SET status=:s WHERE id=:id')->execute([':s' => $status, ':id' => $id]);
    $order = order_detail($pdo, $id);
    $buyerId = (int)$order['buyer_id'];
    notify_user($pdo, $buyerId, 'order_status', 'Order updated', 'Order #' . $id . ' is now ' . $status, ['order_id' => $id]);
    foreach (farmer_ids_for_order($pdo, $id) as $fid) {
      notify_user($pdo, $fid, 'order_status', 'Order updated', 'Order #' . $id . ' is now ' . $status, ['order_id' => $id]);
    }
    json_response(200, ['ok' => true, 'order' => $order]);
  }

  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'admin_orders failed']);
}
