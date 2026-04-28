<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_login($pdo);
$uid = (int)$u['id'];
$method = $_SERVER['REQUEST_METHOD'];

try {
  if ($method === 'GET') {
    $with = isset($_GET['with']) ? (int)$_GET['with'] : 0;
    if ($with > 0) {
      $stmt = $pdo->prepare('
        SELECT m.*, uf.username AS from_username, ut.username AS to_username
        FROM messages m
        JOIN users uf ON uf.id = m.from_user_id
        JOIN users ut ON ut.id = m.to_user_id
        WHERE (m.from_user_id=:a AND m.to_user_id=:b) OR (m.from_user_id=:b AND m.to_user_id=:a)
        ORDER BY m.id ASC
        LIMIT 500
      ');
      $stmt->execute([':a' => $uid, ':b' => $with]);
      json_response(200, ['ok' => true, 'messages' => $stmt->fetchAll()]);
    }
    $stmt = $pdo->prepare('
      SELECT u.id, u.username, u.role, MAX(m.id) AS last_id, MAX(m.created_at) AS last_at
      FROM messages m
      JOIN users u ON u.id = CASE WHEN m.from_user_id = :uid THEN m.to_user_id ELSE m.from_user_id END
      WHERE m.from_user_id = :uid OR m.to_user_id = :uid
      GROUP BY u.id, u.username, u.role
      ORDER BY last_at DESC
      LIMIT 100
    ');
    $stmt->execute([':uid' => $uid]);
    json_response(200, ['ok' => true, 'conversations' => $stmt->fetchAll()]);
  }

  if ($method === 'POST') {
    $body = read_json_body();
    $to = (int)($body['to_user_id'] ?? 0);
    $text = trim((string)($body['body'] ?? ''));
    if ($to <= 0 || $text === '') json_response(400, ['ok' => false, 'error' => 'to_user_id and body required']);
    if ($to === $uid) json_response(400, ['ok' => false, 'error' => 'Cannot message yourself']);
    $pdo->prepare('INSERT INTO messages (from_user_id, to_user_id, body) VALUES (:f,:t,:b)')
      ->execute([':f' => $uid, ':t' => $to, ':b' => $text]);
    notify_user($pdo, $to, 'message', 'New message', 'You have a new message', ['from_user_id' => $uid]);
    json_response(200, ['ok' => true, 'id' => (int)$pdo->lastInsertId()]);
  }

  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'messages failed']);
}
