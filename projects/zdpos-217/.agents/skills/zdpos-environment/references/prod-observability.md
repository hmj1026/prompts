# PROD 觀測座標：站台 DB 主機與 slow log

PROD 調查（慢查詢、慢請求、log 調閱）前讀這份。全部是唯讀操作；遠端一律用 pipe，不落檔。

## 站台 → DB 主機（2026-11-04 驗證）

| 主機 | 站台 | DB host | 引擎 | dbname |
|---|---|---|---|---|
| `vm1` | `cpos.zdn.tw/<site>`（wanpo、chpos001、ane001、mimd、onongs、nanhai 等） | Cloud SQL `10.8.202.2` | MySQL 8.0.31-google，多為 InnoDB | `zdpos_<site>`（少數站台的 config 會覆寫，例如 mimd） |
| `vm2` | `pos.zdn.tw` 系列（sanzhi、feca、wine、cp、singya 等） | 本機 XAMPP `/opt/lampp` | MariaDB 10.1.38，多為 MyISAM | `zdpos_<site>` |

- 站台的碼基：`/var/www/cpos.zdn.tw/<site>/index.php` 以相對路徑載入 `../../<碼基目錄>/protected/config/<site>.php`；碼基目錄因站台而異（`zdpos_217`、`zdpos_217_wanpo`、`zdpos_217_stable`、`zdpos_beta_test`）。查碼基看 `index.php` 的 `$config` 那一行即可。
- 取 DB host 只用白名單抽取：`grep -o "mysql:host=[^;]*;dbname=[^;\"']*" <file>`。設定檔含帳密，不 `cat`、不 `sed` 整檔。
- `mysql-uat-remote` MCP 與 vm1 站台連的是同一個 Cloud SQL 實例（版本相同，可見 `zdpos_wanpo`）。
- VM2 曾有庫遷到 Cloud SQL：chpos001、ane001、puff 在 VM2 slow log 中 2025-12 起歸零，現由 vm1 站台連 Cloud SQL。

## 慢請求與慢查詢的證據來源

| 來源 | 位置 | 有 SQL 文字嗎 | 備註 |
|---|---|---|---|
| vm1 PHP-FPM slow log | `/var/log/nginx/php5.6-fpm-www-slow.log`（輪替 `.1`、`.N.gz`）；PHP 8.0（eiv2）為 `php8.0-fpm-www-slow.log` | 否，只有 stack | 門檻 `request_slowlog_timeout = 5`（`/etc/php/5.6/fpm/pool.d/www.conf`）；每筆 entry 的 `script_filename` 可分站台 |
| vm1 nginx access log | `/var/log/nginx/https-cpos.zdn.tw.access.log*` | 否 | `log_format` 沒有 `$request_time`，耗時只能用 slow log 時間減 5 秒對照推算；excel5 匯出的 `seacher` 在 GET query string 裡 |
| vm1 本機 MySQL slow log | 關閉（`mysqld.cnf` 三行為註解），`mysql.slow_log` 表為空 | — | vm1 站台的 DB 不在本機，這份 log 與站台查詢無關 |
| Cloud SQL slow log | 關閉（`slow_query_log = 0`） | — | `performance_schema` digest 表已滿 10,000 筆，新查詢不會進來 |
| vm2 MariaDB slow log | `/opt/lampp/var/mysql/web-service-2-slow.log`（單檔、無輪替，需 `sudo -n`） | 是 | `long_query_time = 10`；凌晨 03–05 時大量 `select /*!N sql_no_cache */ *` 是全表讀取（疑為備份），統計時要排除 |

## 統計時的陷阱

- 子代理在本機用 zsh：`--include=*.php` 這類 glob 要加引號，否則指令不會照預期執行。
- awk 程式用 `ssh host 'sudo -n awk -f /dev/stdin <log>' < script.awk` 從 stdin 傳入，比在單引號裡跳脫可靠。
- vm1 slow log 一筆請求只取樣一次 stack，只能說明「第 5 秒時卡在哪」，不能證明整段耗時都在那裡。
