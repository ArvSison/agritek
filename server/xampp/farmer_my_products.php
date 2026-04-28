<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_roles($pdo, ['farmer']);
$fid = (int)$u['id'];

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
}

try {
  $stmt = $pdo->prepare('SELECT * FROM products WHERE farmer_id=:f ORDER BY id DESC');
  $stmt->execute([':f' => $fid]);
  $rows = $stmt->fetchAll();
  $products = array_map(function($r) {
    $price = number_format((float)$r['price_php'], 2, '.', '');
    return [
      'id' => (int)$r['id'],
      'name' => $r['name'],
      'price' => "₱{$price}/{$r['unit']}",
      'harvestDate' => $r['harvest_date'],
      'image' => $r['image_url'],
      'description' => $r['description'],
      'status' => $r['status'],
    ];
  }, $rows);
  json_response(200, ['ok' => true, 'products' => $products]);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'farmer_my_products failed']);
}
