<?php
declare(strict_types=1);

// Basic JSON API helpers + DB connection.
// If your phpMyAdmin/XAMPP credentials differ, update these values.

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Admin-Gate');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  // Some browsers require the allow-* headers to be present on the preflight response.
  header('Access-Control-Allow-Origin: *');
  header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Admin-Gate');
  header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
  http_response_code(204);
  exit;
}

$DB_HOST = '127.0.0.1';
$DB_NAME = 'agritek';
$DB_USER = 'root';
$DB_PASS = ''; // default XAMPP

function json_response(int $status, array $data): void {
  http_response_code($status);
  echo json_encode($data, JSON_UNESCAPED_SLASHES);
  exit;
}

function read_json_body(): array {
  $raw = file_get_contents('php://input');
  if ($raw === false || trim($raw) === '') return [];
  $data = json_decode($raw, true);
  if (!is_array($data)) {
    json_response(400, ['ok' => false, 'error' => 'Invalid JSON body']);
  }
  return $data;
}

try {
  $pdo = new PDO(
    "mysql:host={$DB_HOST};dbname={$DB_NAME};charset=utf8mb4",
    $DB_USER,
    $DB_PASS,
    [
      PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
      PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]
  );
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'DB connection failed']);
}

