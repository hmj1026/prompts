# DEV web 主機設定（`ssh dev`，www.zdpos.tw）

主機設定以實機為準。先跑下方探針再下結論；playbook 與本檔快照都可能過時。

## 唯讀探針

```bash
# FPM：每個 PHP 版本的 pool（user、socket、pm、log）
ssh dev 'ls /etc/php/*/fpm/pool.d/; for v in 5.6 8.3 8.4; do echo "--$v"; grep -hE "^\[|^user|^listen =|^pm|^php_|^env\[" /etc/php/$v/fpm/pool.d/*.conf; done'
# nginx：http 層 include、upstream、生效 vhost（去註解）
ssh dev 'cat /etc/nginx/conf.d/php-fpm.conf; ls /etc/nginx/conf.d/; ls -l /etc/nginx/sites-enabled/ | grep zdpos'
ssh dev 'grep -vE "^\s*#|^\s*$" /etc/nginx/sites-available/php56/www.zdpos.tw.443.conf'
# 站台佈局：薄入口 symlink、碼基靜態目錄
ssh dev 'ls -l /var/www/public/www.zdpos.tw/; ls -la /var/www/public/www.zdpos.tw/zdpos_develop-splitbill/'
# runtime 實際 ini
ssh dev 'php-fpm8.4 -i | grep -E "^(short_open_tag|session.save_path|opcache.validate_timestamps) "'
```

## 快照（2026-10-28）

- **FPM**：每個 PHP 版本一個 `www` pool（5.6、8.3、8.4），沒有站台專屬 pool。三者 `user/group=deploy`、`pm.max_children=100`，error log 寫在 `/var/log/nginx/php<ver>-fpm-error.log`。php.ini 的 `short_open_tag` 在 5.6 與 8.4 都是 On。
- **upstream**：`/etc/nginx/conf.d/php-fpm.conf` 定義 `php56-fpm-sock`、`php83-fpm-sock`、`php84-fpm-sock`。
- **vhost**：生效檔是 `sites-available/php56/www.zdpos.tw.{443,80}.conf`，`sites-available/php84/` 為空。`root /var/www/public/www.zdpos.tw`；`location ~ ^/([^/]+)` 以 `try_files … /$firstdir/index.php` 路由各站；server 層 `location ~ \.php$` 處理 PHP，SCRIPT_FILENAME 用 `$realpath_root`。443 另有 `/{client}/(easypos|bbpos|adpos2|MIDC2|order|lin2)` 巢狀區塊，寫死 5.6。
- **站台**：`/var/www/public/www.zdpos.tw/{site}` 以 symlink 指向 `/var/www/www.zdpos.tw/{site}`（薄入口）。`/var/www/public/www.zdpos.tw/zdpos_{codebase}/` 是實體目錄，內含 `assets ckeditor css images js media` 六個 symlink，指回碼基。同一個 docroot 下也放了非 zdpos 專案（`ZdnServiceApi*`、`mypos*`、`LineAtMember`、`*.zdpos.app` 等）。
- **upload**：server 層的 `^/upload/` deny 只擋網站根目錄。各站自己的 `/{site}/upload/*.php` 不在 deny 範圍內，見 memory `trap-zdpos-www-upload-deny-root-only.md`。

PHP 8.4 並行測試與逐站遷移（nginx `map` 決定 runtime）：`/home/paul/projects/zdpos-217-docs/docs/operations/playbooks/dev-php84-site-deployment.md`。
