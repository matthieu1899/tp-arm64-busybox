<?php
// Page dynamique servie par httpd (BusyBox) + php-cgi statique sur ARM64
$uptime = (float) explode(' ', file_get_contents('/proc/uptime'))[0];
$load   = sys_getloadavg();
$nom    = isset($_GET['nom']) ? htmlspecialchars($_GET['nom'], ENT_QUOTES, 'UTF-8') : '';
?>
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Linux embarqué ARM64</title>
<style>
  body { font-family: sans-serif; max-width: 40em; margin: 2em auto; }
  td { padding: .2em 1em .2em 0; }
  code { background: #eee; padding: 0 .3em; }
</style>
</head>
<body>
<h1>Linux embarqué ARM64 — BusyBox + PHP</h1>
<?php if ($nom !== ''): ?>
  <p>Bonjour <strong><?= $nom ?></strong> !</p>
<?php endif; ?>
<table>
  <tr><td>Machine</td><td><code><?= htmlspecialchars(php_uname('n')) ?></code></td></tr>
  <tr><td>Architecture</td><td><code><?= htmlspecialchars(php_uname('m')) ?></code></td></tr>
  <tr><td>Noyau</td><td><code><?= htmlspecialchars(php_uname('r')) ?></code></td></tr>
  <tr><td>PHP</td><td><code><?= PHP_VERSION ?> (<?= PHP_SAPI ?>)</code></td></tr>
  <tr><td>Date (cible)</td><td><?= date('d/m/Y H:i:s') ?></td></tr>
  <tr><td>Uptime</td><td><?= sprintf('%d min %02d s', intdiv((int) $uptime, 60), (int) $uptime % 60) ?></td></tr>
  <tr><td>Charge</td><td><?= implode(' / ', array_map(fn($l) => sprintf('%.2f', $l), $load)) ?></td></tr>
  <tr><td>Votre IP</td><td><?= htmlspecialchars($_SERVER['REMOTE_ADDR'] ?? '?') ?></td></tr>
</table>
<form method="get">
  <p><input name="nom" placeholder="Votre prénom"> <button>Envoyer</button></p>
</form>
</body>
</html>
