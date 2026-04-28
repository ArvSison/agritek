<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_login($pdo);
$meRole = (string)$u['role'];
$roleFilter = (string)($_GET['role'] ?? '');
if (!in_array($roleFilter, ['buyer', 'farmer'], true)) {
  json_response(400, ['ok' => false, 'error' => 'role=buyer|farmer required']);
}
if (($meRole === 'buyer' && $roleFilter !== 'farmer') || ($meRole === 'farmer' && $roleFilter !== 'buyer')) {
  json_response(403, ['ok' => false, 'error' => 'Forbidden role filter']);
}

try {
  $stmt = $pdo->prepare("SELECT id, username, email, role FROM users WHERE role=:r AND status='active' ORDER BY username ASC LIMIT 200");
  $stmt->execute([':r' => $roleFilter]);
  json_response(200, ['ok' => true, 'users' => $stmt->fetchAll()]);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'users_discovery failed']);
}
