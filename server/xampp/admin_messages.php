<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

require_admin_access($pdo);
$method = $_SERVER['REQUEST_METHOD'];

function first_admin_id(PDO $pdo): int {
  $row = $pdo->query("SELECT id FROM users WHERE role='admin' AND status='active' ORDER BY id ASC LIMIT 1")->fetch();
  return $row ? (int)$row['id'] : 0;
}

try {
  if ($method === 'GET') {
    $stmt = $pdo->query('
      SELECT m.*, uf.username AS from_username, ut.username AS to_username
      FROM messages m
      JOIN users uf ON uf.id = m.from_user_id
      JOIN users ut ON ut.id = m.to_user_id
      ORDER BY m.id DESC
      LIMIT 200
    ');
    json_response(200, ['ok' => true, 'messages' => $stmt->fetchAll()]);
  }

  if ($method === 'POST') {
    $from = first_admin_id($pdo);
    if ($from <= 0) json_response(500, ['ok' => false, 'error' => 'No admin user']);
    $body = read_json_body();
    $to = (int)($body['to_user_id'] ?? 0);
    $text = trim((string)($body['body'] ?? ''));
    if ($to <= 0 || $text === '') json_response(400, ['ok' => false, 'error' => 'to_user_id and body required']);
    $pdo->prepare('INSERT INTO messages (from_user_id, to_user_id, body) VALUES (:f,:t,:b)')
      ->execute([':f' => $from, ':t' => $to, ':b' => $text]);
    notify_user($pdo, $to, 'message', 'Message from admin', $text, ['from_user_id' => $from]);
    json_response(200, ['ok' => true, 'id' => (int)$pdo->lastInsertId()]);
  }

  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
} catch (Throwable $e) {
  json_response(500, ['ok' => false, 'error' => 'admin_messages failed']);
}
