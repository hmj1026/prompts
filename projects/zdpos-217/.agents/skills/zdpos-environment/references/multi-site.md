# Multi-site deployment（thin-entry）

> zdpos-environment skill 子檔。觸發：cpos.zdpos.tw / www.zdpos.tw / www.posdev.test / oklao(2/3) / dev4 / 某 URL 跑哪份碼基 / 改了沒反應 / X:Y:Z 磁碟。

## 多站部署架構（thin-entry：LOCAL / DEV / PROD 共通）

**存取途徑（正規 = SSH）**：遠端檔案 / 設定**應走 SSH**（見 `environments.md` `## SSH`；Claude 不能直接 SSH → 請使用者代跑貼回）。**次選 = 從 WSL 經 Windows interop 直讀 UNC**（非正規、不可移植：能讀取靠的是**此 Windows 主機**已具 SMB 存取權，換機可能失效；WSL 內無 `smbclient`/`mount.cifs`，**不走 cifs-utils**）：

> - **直讀 UNC（免 map drive、免另輸帳密）**：`/mnt/c/Windows/System32/cmd.exe /c "dir \\104.199.182.52\pos"`（列目錄）、`... /c "type \\104.199.182.52\logs\2026-06\xxx.log"`（讀檔），輸出 `| tr -d '\r'`。`type X:\path\file` 只是「該機已 `net use` map 成磁碟」時的捷徑，**非前提**（WSL **不自動掛**這些網路碟）。
> - **批次掃檔需原生 Linux 路徑時**（cx / grep / Read 多檔）：一次性掛載 `sudo mount -t drvfs '\\104.199.182.52\pos' /mnt/vm2pos`，之後即可用原生工具掃。
> - SMB port 445 對 vm1 / vm2 可達；ICMP `ping` 被擋屬正常，不影響檔案存取。實測 2026-06-25：vm2 `\pos` / `\logs` 兩 share 皆可直讀（無 map、無帳密提示）。

**Windows / UNC share 對應**（直讀 UNC 不需 map；下方 X/Y/Z 為此機 `net use` 已 map 的捷徑，vm2 未 map 但可直讀）：

| UNC | drive | 機器 / 路徑 |
|---|---|---|
| `\\104.199.245.231\cpos` | X: | VM1 `/var/www/`（cpos.zdpos.tw 多站 + zdpos_217 / zdpos_218） |
| `\\104.199.245.231\logs` | Y: | VM1 logs |
| `\\104.199.182.52\pos` | (直讀, 未 map) | **VM2** `/var/www/`（pos.zdn.tw 多站 / ZCPOS217 `zcpos_217`…）|
| `\\104.199.182.52\logs` | (直讀, 未 map) | **VM2** logs（月份資料夾 `YYYY-MM`）|
| `\\192.168.2.231\public` | Z: | DEV(`dev`) `/var/www/`（含 `www.zdpos.tw/` 多站） |

**Thin-entry（URL 入口 vs 碼基分離）**：每個 URL 是薄入口資料夾（`<url>/index.php` ~760B，僅 index.php + assets/log/upload/media，**無 protected/、domain/**），`index.php` 內：

```php
$config = '<相對路徑>/<tree>/protected/config/<name>.php';   // 真正碼基 = 共用樹
$yii    = '<相對路徑>/yii_framework/yii.php';
```

改某站 → 改它指向的**共用碼基樹**，不是入口資料夾（入口深度：VM1 cpos `../../../development/<tree>/…`；local / DEV 入口與碼基同層 `../<tree>/…`）。已於各機器驗證：

| 環境 / URL | 機器 / 碼基樹 | config | DB |
|---|---|---|---|
| **PROD** `cpos.zdpos.tw/oklao3` | VM1 `development/zdpos_oklao_test` | `oklao3.php` | `zdpos_oklao3` |
| **PROD** `cpos.zdpos.tw/oklao2` | VM1 `development/zdpos_oklao` | `oklao2.php` | `zdpos_oklao2` |
| **DEV** `www.zdpos.tw/dev` | DEV `zdpos_develop` | `dev.php` | `zdpos_dev` |
| **LOCAL** `www.posdev.test/dev4` | local `zdpos-217`（本 working tree，編輯即生效，詳 `environments.md` ### Local dev4 entry） | `dev4.php` | `zdpos_dev_2` |

**DB**：config 取 DB 名兩種來源 —— 根 `dbConnectParams.php`（`zdpos_<use_name>`，如 oklao3 → `zdpos_oklao3`）或 config 內硬寫死（`dev.php` `$db_name="zdpos_dev"`、`dev4.php` `"zdpos_dev_2"`）。Cloud SQL host `10.8.202.2` + SSL client cert `/etc/gcpencrypt/cloud-sql/*.pem`（帳密見部署機 config，勿外流）。

⚠️ **opcache 假象（遠端）**：改共用樹的 PHP（尤其 `domain/` 類別）後，遠端 PHP opcache 仍服務舊 bytecode →「改了沒反應」，必 reset（local Docker 的 reset 見 `environments.md` ### Local dev4 entry）。2026-06-25 oklao3 實例：`PlatformBrand::isOklao()` 加 `zdpos_oklao3` 白名單後未 reset → `isOklao()` 續回 false → 品項留在 `td5` 右下角；reset 後回 `#right_box` 右側欄。
⚠️ **`development/zdpos_oklao_test` 名為 test 卻是 live `cpos.zdpos.tw/oklao3` 的碼基且連 production DB**；改它＝動線上。
