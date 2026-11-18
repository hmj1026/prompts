測試：bash protected/tests/scripts/run-tests.sh fast（不帶參數＝full，含 DB）；語法 php -l <file>
PHP 5.6：禁 ??、純量型別、fn() =>；陣列用 []
DDD：protected/（Yii MVC）| domain/（Service／Repository 契約）| infrastructure/（Repository／DB／外部 API）
Docker：pos_php（PHP 5.6.40）／pos_mysql（MySQL 5.7）
MySQL sql_mode：docker exec -i pos_mysql mysql -e "SELECT @@sql_mode"
Yii 1.1：~/projects/yii_framework/；listener 接線在 protected/config/main.php 的 events 區塊
dev4 改 view／PHP 後：docker exec -i pos_php sh -c 'kill -USR2 1'（opcache revalidate_freq=60）
