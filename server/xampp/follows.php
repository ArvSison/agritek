<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_login($pdo);
$uid = (int)$u['id'];
$method = $_SERVER['REQUEST_METHOD'];

try {
  if ($method === 'GET') {
    $stmt = $pdo->prepare('
      SELECT u.id, u.username, u.role, f.created_at
      FROM follows f
      JOIN users u ON u.id = f.following_id
      WHERE f.follower_id = :me
      ORDER BY f.created_at DESC
    ');
    $stmt->execute([':me' => $uid]);
    json_response(200, ['ok' => true, 'following' => $stmt->fetchAll()]);
  }

  if ($method === 'POST') {
    $body = read_json_body();
    $fid = (int)($body['user_id'] ?? 0);
    if ($fid <= 0 || $fid === $uid) json_response(400, ['ok' => false, 'error' => 'user_id required']);
    $pdo->prepare('INSERT IGNORE INTO follows (follower_id, following_id) VALUES (:a,:b)')->execute([':a' => $uid, ':b' => $fid]);
    notify_user($pdo, $fid, 'follow', 'New follower', (string)$u['username'] . ' followed you', ['follower_id' => $uid]);
    json_response(200, ['ok' => true]);
  }

  if ($method === 'DELETE') {
    $fid = (int)($_GET['user_id'] ?? 0);
    if ($fid <= 0) json_response(400, ['ok' => false, 'error' => 'user_id required']);
    $pdo->prepare('DELETE FROM follows WHERE follower_id=:a AND following_id=:b')->execute([':a' => $uid, ':b' => $fid]);
    json_response(200, ['ok' => true]);
  }

  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'follows failed']);
}
