<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_roles($pdo, ['farmer']);
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
}

$body = read_json_body();
$name = trim((string)($body['name'] ?? ''));
$price = $body['price'] ?? null;
$unit = trim((string)($body['unit'] ?? 'kg'));
$harvest = trim((string)($body['harvest_date'] ?? ''));
$image = trim((string)($body['image_url'] ?? ''));
$desc = trim((string)($body['description'] ?? ''));
$loc = trim((string)($body['farmer_location'] ?? ''));

if ($name === '' || $price === null || !is_numeric($price)) {
  json_response(400, ['ok' => false, 'error' => 'name and numeric price required']);
}

$farmerId = (int)$u['id'];
$farmerName = (string)$u['username'];

try {
  $harvestDate = $harvest !== '' ? $harvest : null;
  $stmt = $pdo->prepare('
    INSERT INTO products (name, price_php, unit, harvest_date, image_url, description, farmer_name, farmer_location, farmer_id, status)
    VALUES (:n,:p,:u,:h,:img,:d,:fn,:loc,:fid, \'pending\')
  ');
  $stmt->execute([
    ':n' => $name,
    ':p' => (float)$price,
    ':u' => $unit !== '' ? $unit : 'kg',
    ':h' => $harvestDate,
    ':img' => $image !== '' ? $image : null,
    ':d' => $desc !== '' ? $desc : null,
    ':fn' => $farmerName,
    ':loc' => $loc !== '' ? $loc : null,
    ':fid' => $farmerId,
  ]);
  $pid = (int)$pdo->lastInsertId();
  notify_all_admins($pdo, 'product_pending', 'New product pending', "{$farmerName} submitted {$name}", ['product_id' => $pid]);
  json_response(200, ['ok' => true, 'product_id' => $pid, 'status' => 'pending']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'Could not add product']);
}
