<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_roles($pdo, ['buyer']);
$uid = (int)$u['id'];
$method = $_SERVER['REQUEST_METHOD'];

try {
  if ($method === 'GET') {
    $stmt = $pdo->prepare('
      SELECT c.product_id, c.qty, p.name, p.price_php, p.unit, p.image_url, p.status
      FROM cart_items c
      JOIN products p ON p.id = c.product_id
      WHERE c.user_id = :uid
    ');
    $stmt->execute([':uid' => $uid]);
    $rows = $stmt->fetchAll();
    $items = array_map(function($r) {
      $price = number_format((float)$r['price_php'], 2, '.', '');
      return [
        'product_id' => (int)$r['product_id'],
        'qty' => (int)$r['qty'],
        'name' => $r['name'],
        'price' => "₱{$price}/{$r['unit']}",
        'unit' => $r['unit'],
        'price_php' => (float)$r['price_php'],
        'image' => $r['image_url'],
        'product_status' => $r['status'],
      ];
    }, $rows);
    json_response(200, ['ok' => true, 'items' => $items]);
  }

  if ($method === 'POST') {
    $body = read_json_body();
    $pid = (int)($body['product_id'] ?? 0);
    $qty = (int)($body['qty'] ?? 1);
    if ($pid <= 0 || $qty <= 0) json_response(400, ['ok' => false, 'error' => 'product_id and qty required']);
    $chk = $pdo->prepare('SELECT id, status FROM products WHERE id=:id LIMIT 1');
    $chk->execute([':id' => $pid]);
    $p = $chk->fetch();
    if (!$p || $p['status'] !== 'active') {
      json_response(400, ['ok' => false, 'error' => 'Product not available']);
    }
    $stmt = $pdo->prepare('
      INSERT INTO cart_items (user_id, product_id, qty) VALUES (:u,:p,:q)
      ON DUPLICATE KEY UPDATE qty = qty + VALUES(qty)
    ');
    $stmt->execute([':u' => $uid, ':p' => $pid, ':q' => $qty]);
    json_response(200, ['ok' => true]);
  }

  if ($method === 'DELETE') {
    $pid = (int)($_GET['product_id'] ?? 0);
    if ($pid <= 0) json_response(400, ['ok' => false, 'error' => 'product_id required']);
    $pdo->prepare('DELETE FROM cart_items WHERE user_id=:u AND product_id=:p')->execute([':u' => $uid, ':p' => $pid]);
    json_response(200, ['ok' => true]);
  }

  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'cart failed']);
}
