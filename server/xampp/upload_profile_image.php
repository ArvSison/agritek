<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_lib.php';

$u = require_login($pdo);
$uid = (int) $u['id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  json_response(405, ['ok' => false, 'error' => 'Method not allowed']);
}

if (empty($_FILES['image']) || !is_array($_FILES['image'])) {
  json_response(400, ['ok' => false, 'error' => 'No image file (field name: image)']);
}

$f = $_FILES['image'];
if (($f['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
  json_response(400, ['ok' => false, 'error' => 'Upload failed (code ' . (int) ($f['error'] ?? 0) . ')']);
}

$maxBytes = 5 * 1024 * 1024;
$size = (int) ($f['size'] ?? 0);
if ($size <= 0 || $size > $maxBytes) {
  json_response(400, ['ok' => false, 'error' => 'Image must be 1 byte–5 MB']);
}

$tmp = (string) ($f['tmp_name'] ?? '');
if ($tmp === '' || !is_uploaded_file($tmp)) {
  json_response(400, ['ok' => false, 'error' => 'Invalid upload']);
}

$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime = $finfo->file($tmp);
if (!is_string($mime)) {
  json_response(400, ['ok' => false, 'error' => 'Could not detect file type']);
}

$allowed = [
  'image/jpeg' => 'jpg',
  'image/png' => 'png',
  'image/webp' => 'webp',
  'image/gif' => 'gif',
];
$ext = $allowed[$mime] ?? null;
if ($ext === null) {
  json_response(400, ['ok' => false, 'error' => 'Only JPEG, PNG, WebP, or GIF allowed']);
}

$dir = __DIR__ . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR . 'avatars';
if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
  json_response(500, ['ok' => false, 'error' => 'Could not create upload directory']);
}

$name = 'av_' . $uid . '_' . bin2hex(random_bytes(10)) . '.' . $ext;
$dest = $dir . DIRECTORY_SEPARATOR . $name;
if (!move_uploaded_file($tmp, $dest)) {
  json_response(500, ['ok' => false, 'error' => 'Could not save file']);
}

$scriptDir = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/'));
$scriptDir = rtrim($scriptDir, '/');
if ($scriptDir === '') {
  $scriptDir = '';
}
$path = $scriptDir . '/uploads/avatars/' . $name;

$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$publicUrl = $scheme . '://' . $host . $path;

json_response(200, ['ok' => true, 'url' => $publicUrl, 'path' => $path]);
