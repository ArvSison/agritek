<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_login($pdo);
$role = (string)$u['role'];
$uid = (int)$u['id'];
$method = $_SERVER['REQUEST_METHOD'];

function order_json(PDO $pdo, array $o): array {
  $items = $pdo->prepare('SELECT oi.*, p.name FROM order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.order_id=:id');
  $items->execute([':id' => (int)$o['id']]);
  $o['items'] = $items->fetchAll();
  return $o;
}

try {
  if ($method === 'GET') {
    if ($role === 'admin') {
      json_response(403, ['ok' => false, 'error' => 'Use admin_orders for admin']);
    }
    if ($role === 'buyer') {
      $stmt = $pdo->prepare('SELECT o.*, u.username AS buyer_username FROM orders o JOIN users u ON u.id=o.buyer_id WHERE o.buyer_id=:b ORDER BY o.id DESC');
      $stmt->execute([':b' => $uid]);
    } elseif ($role === 'farmer') {
      $stmt = $pdo->prepare('
        SELECT DISTINCT o.*, ub.username AS buyer_username
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.id
        JOIN products p ON p.id = oi.product_id
        JOIN users ub ON ub.id = o.buyer_id
        WHERE p.farmer_id = :fid
        ORDER BY o.id DESC
      ');
      $stmt->execute([':fid' => $uid]);
    } else {
      json_response(403, ['ok' => false, 'error' => 'Forbidden']);
    }
    $rows = $stmt->fetchAll();
    $out = [];
    foreach ($rows as $r) {
      $out[] = order_json($pdo, $r);
    }
    json_response(200, ['ok' => true, 'orders' => $out]);
  }

  if ($method === 'POST') {
    require_roles($pdo, ['buyer']);
    $pdo->beginTransaction();
    $stmt = $pdo->prepare('
      SELECT c.product_id, c.qty, p.price_php, p.status
      FROM cart_items c
      JOIN products p ON p.id = c.product_id
      WHERE c.user_id = :u
    ');
    $stmt->execute([':u' => $uid]);
    $lines = $stmt->fetchAll();
    if (!$lines) {
      $pdo->rollBack();
      json_response(400, ['ok' => false, 'error' => 'Cart is empty']);
    }
    $total = 0.0;
    foreach ($lines as $ln) {
      if ($ln['status'] !== 'active') {
        $pdo->rollBack();
        json_response(400, ['ok' => false, 'error' => 'Cart contains inactive product']);
      }
      $total += (float)$ln['price_php'] * (int)$ln['qty'];
    }
    $pdo->prepare('INSERT INTO orders (buyer_id, status, total_php) VALUES (:b, \'to_pay\', :t)')->execute([':b' => $uid, ':t' => $total]);
    $orderId = (int)$pdo->lastInsertId();
    $ins = $pdo->prepare('INSERT INTO order_items (order_id, product_id, qty, unit_price_php) VALUES (:oid,:pid,:q,:up)');
    foreach ($lines as $ln) {
      $ins->execute([
        ':oid' => $orderId,
        ':pid' => (int)$ln['product_id'],
        ':q' => (int)$ln['qty'],
        ':up' => (float)$ln['price_php'],
      ]);
    }
    $pdo->prepare('DELETE FROM cart_items WHERE user_id=:u')->execute([':u' => $uid]);
    $pdo->commit();

    notify_user($pdo, $uid, 'order_created', 'Order placed', 'Order #' . $orderId . ' created (to pay)', ['order_id' => $orderId]);
    foreach (farmer_ids_for_order($pdo, $orderId) as $fid) {
      notify_user($pdo, $fid, 'order_new', 'New order', 'New order #' . $orderId . ' from buyer', ['order_id' => $orderId]);
    }

    $o = $pdo->prepare('SELECT o.*, u.username AS buyer_username FROM orders o JOIN users u ON u.id=o.buyer_id WHERE o.id=:id');
    $o->execute([':id' => $orderId]);
    json_response(200, ['ok' => true, 'order' => order_json($pdo, $o->fetch())]);
  }

  if ($method === 'PATCH') {
    $body = read_json_body();
    $id = (int)($body['id'] ?? 0);
    $action = (string)($body['action'] ?? '');
    if ($id <= 0 || !in_array($action, ['pay', 'ship', 'receive'], true)) {
      json_response(400, ['ok' => false, 'error' => 'id and action pay|ship|receive required']);
    }
    $stmt = $pdo->prepare('SELECT * FROM orders WHERE id=:id LIMIT 1');
    $stmt->execute([':id' => $id]);
    $order = $stmt->fetch();
    if (!$order) json_response(404, ['ok' => false, 'error' => 'Order not found']);
    $st = (string)$order['status'];

    if ($action === 'pay') {
      require_roles($pdo, ['buyer']);
      if ((int)$order['buyer_id'] !== $uid) json_response(403, ['ok' => false, 'error' => 'Forbidden']);
      if ($st !== 'to_pay') json_response(400, ['ok' => false, 'error' => 'Invalid state']);
      $pdo->prepare('UPDATE orders SET status=\'to_ship\' WHERE id=:id')->execute([':id' => $id]);
    } elseif ($action === 'ship') {
      require_roles($pdo, ['farmer']);
      $farmerIds = farmer_ids_for_order($pdo, $id);
      if (!in_array($uid, $farmerIds, true)) json_response(403, ['ok' => false, 'error' => 'Not your product order']);
      if ($st !== 'to_ship') json_response(400, ['ok' => false, 'error' => 'Invalid state']);
      $pdo->prepare('UPDATE orders SET status=\'to_receive\' WHERE id=:id')->execute([':id' => $id]);
    } elseif ($action === 'receive') {
      require_roles($pdo, ['buyer']);
      if ((int)$order['buyer_id'] !== $uid) json_response(403, ['ok' => false, 'error' => 'Forbidden']);
      if ($st !== 'to_receive') json_response(400, ['ok' => false, 'error' => 'Invalid state']);
      $pdo->prepare('UPDATE orders SET status=\'completed\' WHERE id=:id')->execute([':id' => $id]);
    }

    $o2 = $pdo->prepare('SELECT o.*, u.username AS buyer_username FROM orders o JOIN users u ON u.id=o.buyer_id WHERE o.id=:id');
    $o2->execute([':id' => $id]);
    $fresh = $o2->fetch();
    $st2 = (string)$fresh['status'];
    notify_user($pdo, (int)$fresh['buyer_id'], 'order_status', 'Order updated', 'Order #' . $id . ' is now ' . $st2, ['order_id' => $id]);
    foreach (farmer_ids_for_order($pdo, $id) as $fid) {
      notify_user($pdo, $fid, 'order_status', 'Order updated', 'Order #' . $id . ' is now ' . $st2, ['order_id' => $id]);
    }
    json_response(200, ['ok' => true, 'order' => order_json($pdo, $fresh)]);
  }

  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  json_response(500, ['ok' => false, 'error' => 'orders failed']);
}
