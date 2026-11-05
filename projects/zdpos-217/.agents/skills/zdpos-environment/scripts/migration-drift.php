<?php
// 由 migration-drift.sh 複製到 <repo>/protected/runtime/ 後，在 pos_php 內執行；執行完即刪除。
// 用法：php migration-drift.php <config 名稱，例 dev4> <預期 DB 名稱> list|apply <version>
// 只印 DB 名稱與 migration 版本，不印任何連線設定。
$root = dirname(dirname(__DIR__));
$configName = $argv[1];
$expectDb = $argv[2];
$action = $argv[3];
require_once($root . '/../yii_framework/yii.php');
$config = require($root . '/protected/config/' . $configName . '.php');
Yii::createWebApplication($config);
$db = Yii::app()->db;

$dbName = $db->createCommand('SELECT DATABASE()')->queryScalar();
echo 'database=' . $dbName . PHP_EOL;
if ($dbName !== $expectDb) {
    echo 'ABORT: expected ' . $expectDb . PHP_EOL;
    exit(1);
}

$applied = $db->createCommand('SELECT version FROM tbl_migration')->queryColumn();
$applied = array_flip($applied);
$files = glob($root . '/protected/migrations/m*.php');
$pending = [];
foreach ($files as $file) {
    $version = basename($file, '.php');
    if (!isset($applied[$version])) {
        $pending[] = $version;
    }
}
sort($pending);

if ($action === 'list') {
    echo 'pending=' . count($pending) . PHP_EOL;
    foreach ($pending as $version) {
        echo $version . PHP_EOL;
    }
    exit(0);
}

if ($action === 'apply') {
    $version = $argv[4];
    if (!in_array($version, $pending, true)) {
        echo 'ABORT: ' . $version . ' is not pending' . PHP_EOL;
        exit(1);
    }
    require_once($root . '/protected/migrations/' . $version . '.php');
    $migration = new $version();
    $migration->setDbConnection($db);
    if ($migration->up() === false) {
        echo 'ABORT: ' . $version . ' failed' . PHP_EOL;
        exit(1);
    }
    $db->createCommand()->insert('tbl_migration', ['version' => $version, 'apply_time' => time()]);
    echo $version . ' applied' . PHP_EOL;
    exit(0);
}

echo 'unknown action' . PHP_EOL;
exit(2);
