<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
}

try {
  $stmt = $pdo->query('
    SELECT
      p.id,
      p.name,
      p.price_php,
      p.unit,
      p.harvest_date,
      p.image_url,
      p.description,
      p.farmer_name,
      p.farmer_location,
      p.farmer_id,
      u.username AS farmer_username
    FROM products p
    LEFT JOIN users u ON u.id = p.farmer_id
    WHERE p.status = \'active\'
    ORDER BY p.id DESC
    LIMIT 200
  ');
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
      'farmerName' => $r['farmer_name'],
      'farmerLocation' => $r['farmer_location'],
      'farmerId' => $r['farmer_id'] !== null ? (int)$r['farmer_id'] : null,
      'farmerUsername' => $r['farmer_username'],
      'weight' => '10',
    ];
  }, $rows);

  json_response(200, ['ok' => true, 'products' => $products]);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'Products fetch failed']);
}
