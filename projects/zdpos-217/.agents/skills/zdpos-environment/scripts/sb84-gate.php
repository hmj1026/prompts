<?php
// sb84 拆帳回歸閘門的設定切換工具（只作用於 zdpos_sb84；不輸出帳密與 host）
// 用法：php8.4 sb84-gate.php state
//       php8.4 sb84-gate.php module 0|1            SplitBill 開關（SplitBillLossInv 永遠維持 0）
//       php8.4 sb84-gate.php buttons backup|hide|restore
//       php8.4 sb84-gate.php param backup|set <值>|restore   （splitBillItemNos）
//       php8.4 sb84-gate.php order <10 碼單號>     唯讀：單據、暫存、拆帳、發票摘要（QA 核對用）
//       php8.4 sb84-gate.php tables                唯讀：有單號或鎖的桌位
// QA 代理只可執行 state／order／tables；module／buttons／param 由主控執行。
ini_set('display_errors', '0');
$_SERVER['HTTP_HOST'] = 'localhost'; $_SERVER['SERVER_PORT'] = 80;
require_once '/var/www/yii_framework-fork/yii.php';
$dir = __DIR__;
$cmd = isset($argv[1]) ? $argv[1] : ''; $arg = isset($argv[2]) ? $argv[2] : ''; $val = isset($argv[3]) ? $argv[3] : null;
try {
    $c = require '/var/www/zdpos_218_sb84/protected/config/sb84.php';
    $d = $c['components']['db'];
    $pdo = new PDO($d['connectionString'], $d['username'], $d['password'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
} catch (Throwable $e) { echo "CONNECT_FAILED\n"; exit(2); }
$db = $pdo->query('SELECT DATABASE()')->fetchColumn();
if ($db !== 'zdpos_sb84') { echo "WRONG_DB {$db}\n"; exit(3); }
$one = function ($sql, $p = []) use ($pdo) { $s = $pdo->prepare($sql); $s->execute($p); return $s->fetchColumn(); };
$rows = function ($sql, $p = []) use ($pdo) { $s = $pdo->prepare($sql); $s->execute($p); return $s->fetchAll(PDO::FETCH_ASSOC); };
$btnSql = "SELECT b.* FROM data_button b JOIN data_action a ON a.action_id=b.action_id WHERE a.action_method='splitBill.open' ORDER BY b.button_id";
$btnFile = "{$dir}/buttons.json"; $paramFile = "{$dir}/param.json";
$save = function ($file, $data) { if (file_exists($file)) { echo "BACKUP_EXISTS {$file}\n"; return; } file_put_contents($file, json_encode($data, JSON_UNESCAPED_UNICODE)); chmod($file, 0600); echo "BACKUP_SAVED {$file}\n"; };
$state = function () use ($one, $rows, $btnSql) {
    foreach ($rows("SELECT module_name, available FROM customer_module WHERE module_name IN ('SplitBill','SplitBillLossInv') ORDER BY 1") as $r) { echo "module {$r['module_name']}={$r['available']}\n"; }
    foreach ($rows($btnSql) as $r) { echo "button id={$r['button_id']} station={$r['station_id']} page={$r['page']} index={$r['index']}\n"; }
    echo 'buttons=', count($rows($btnSql)), "\n";
    echo 'splitBillItemNos=', $one("SELECT config_value FROM system_config WHERE config_name='splitBillItemNos'"), "\n";
    echo 'open_sessions=', $one("SELECT COUNT(*) FROM split_bill_session WHERE state IN ('ACTIVE','FINALIZING','NEEDS_RECONCILE')"), "\n";
    echo 'locked_tables=', $one("SELECT COUNT(*) FROM data_table WHERE store_no='001' AND (`lock`<>'' OR lock_salno IS NOT NULL)"), "\n";
};
if ($cmd === 'state') { $state(); exit(0); }
if ($cmd === 'order') {
    if (!preg_match('/^[0-9]{10}$/', $arg)) { echo "USAGE order <10 碼單號>\n"; exit(1); }
    $p = [$arg];
    foreach ($rows("SELECT station_no, table_name, `lock`, list_sum, LENGTH(temp_data) json_len FROM sales_temp WHERE store_no='001' AND sale_no=?", $p) as $r) { echo 'sales_temp ', json_encode($r, JSON_UNESCAPED_UNICODE), "\n"; }
    foreach (['sales_temp_detail', 'sales_temp_list', 'sales_temp_itemlist', 'sales_temp_customer', 'sales_temp_paymentlist'] as $t) { echo "{$t}=", $one("SELECT COUNT(*) FROM {$t} WHERE store_no='001' AND sales_no=?", $p), "\n"; }
    echo 'sales_temp_detail_lock=', $one("SELECT GROUP_CONCAT(DISTINCT `lock`) FROM sales_temp_detail WHERE store_no='001' AND sales_no=?", $p), "\n";
    foreach ($rows("SELECT station_no, table_name, sales_sum, pay_total, taxid, order_type FROM sales_receipt WHERE store_no='001' AND sales_no=?", $p) as $r) { echo 'sales_receipt ', json_encode($r, JSON_UNESCAPED_UNICODE), "\n"; }
    echo 'invalid_receipt=', $one("SELECT COUNT(*) FROM invalid_receipt WHERE store_no='001' AND sales_no=?", $p), "\n";
    echo 'allowance_lines=', $one("SELECT COUNT(*) FROM allowance_receiptlist WHERE store_no='001' AND sales_no=?", $p), "\n";
    echo 'invoices=', $one("SELECT GROUP_CONCAT(CONCAT(invoice_number, IF(customer_taxid<>'', CONCAT('/', customer_taxid), ''))) FROM invoice_record WHERE store_no='001' AND sales_no=?", $p), "\n";
    foreach ($rows("SELECT state, mode, owner_station, version FROM split_bill_session WHERE store_no='001' AND source_no=?", $p) as $r) { echo 'split_session ', json_encode($r), "\n"; }
    $kids = $rows("SELECT r.target_no, sr.sales_sum, (SELECT GROUP_CONCAT(i.invoice_number) FROM invoice_record i WHERE i.store_no=r.store_no AND i.sales_no=r.target_no) inv FROM sales_relation r LEFT JOIN sales_receipt sr ON sr.store_no=r.store_no AND sr.sales_no=r.target_no WHERE r.store_no='001' AND r.source_no=? ORDER BY r.seq", $p);
    foreach ($kids as $r) { echo 'child ', json_encode($r), "\n"; }
    exit(0);
}
if ($cmd === 'tables') {
    foreach ($rows("SELECT name, sale_no, `lock`, lock_salno FROM data_table WHERE store_no='001' AND (sale_no<>'' OR `lock`<>'' OR lock_salno IS NOT NULL) ORDER BY name") as $r) { echo 'table ', json_encode($r, JSON_UNESCAPED_UNICODE), "\n"; }
    echo 'open_sessions=', $one("SELECT COUNT(*) FROM split_bill_session WHERE state IN ('ACTIVE','FINALIZING','NEEDS_RECONCILE')"), "\n";
    exit(0);
}
if (!in_array($cmd, ['module', 'buttons', 'param'], true)) { echo "USAGE\n"; exit(1); }
if ($one("SELECT COUNT(*) FROM split_bill_session WHERE state IN ('ACTIVE','FINALIZING','NEEDS_RECONCILE')") > 0) { echo "STOP open split sessions\n"; exit(4); }
if ($cmd === 'module' && in_array($arg, ['0', '1'], true)) {
    $pdo->exec("UPDATE customer_module SET available={$arg} WHERE module_name='SplitBill'");
    $pdo->exec("UPDATE customer_module SET available=0 WHERE module_name='SplitBillLossInv'");
} elseif ($cmd === 'buttons' && $arg === 'backup') {
    $save($btnFile, $rows($btnSql));
} elseif ($cmd === 'buttons' && $arg === 'hide') {
    if (!file_exists($btnFile)) { echo "STOP no backup\n"; exit(5); }
    $ids = array_map(function ($r) { return (int) $r['button_id']; }, json_decode(file_get_contents($btnFile), true));
    if ($ids) { echo 'deleted=', $pdo->exec('DELETE FROM data_button WHERE button_id IN (' . implode(',', $ids) . ')'), "\n"; }
} elseif ($cmd === 'buttons' && $arg === 'restore') {
    if (!file_exists($btnFile)) { echo "STOP no backup\n"; exit(5); }
    $n = 0;
    foreach (json_decode(file_get_contents($btnFile), true) as $r) {
        if ($one('SELECT COUNT(*) FROM data_button WHERE button_id=?', [$r['button_id']])) { continue; }
        $cols = array_keys($r);
        $s = $pdo->prepare('INSERT INTO data_button (`' . implode('`,`', $cols) . '`) VALUES (' . implode(',', array_fill(0, count($cols), '?')) . ')');
        $s->execute(array_values($r)); $n++;
    }
    echo "restored={$n}\n";
} elseif ($cmd === 'param' && $arg === 'backup') {
    $save($paramFile, ['value' => $one("SELECT config_value FROM system_config WHERE config_name='splitBillItemNos'")]);
} elseif ($cmd === 'param' && $arg === 'set' && $val !== null) {
    if (!file_exists($paramFile)) { echo "STOP no backup\n"; exit(5); }
    $s = $pdo->prepare("UPDATE system_config SET config_value=? WHERE config_name='splitBillItemNos'"); $s->execute([$val]);
} elseif ($cmd === 'param' && $arg === 'restore') {
    if (!file_exists($paramFile)) { echo "STOP no backup\n"; exit(5); }
    $b = json_decode(file_get_contents($paramFile), true);
    $s = $pdo->prepare("UPDATE system_config SET config_value=? WHERE config_name='splitBillItemNos'"); $s->execute([$b['value']]);
} else { echo "USAGE\n"; exit(1); }
$state();
