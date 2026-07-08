DDD layers: protected/ (Yii Controller/Model/View) | domain/ (Service/Repository contracts) | infrastructure/ (DB / cache / external API)
Yii 1.1 framework: ~/projects/yii_framework/ | Docker: pos_php (PHP 5.6 + Yii) / pos_mysql (MySQL 5.7)
PHPUnit cmd: docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php phpunit -c protected/tests/phpunit.xml [--testsuite unit|integration]
MySQL sql_mode check: docker exec -i pos_mysql mysql -e "SELECT @@sql_mode" （確認是否含 STRICT_TRANS_TABLES）
Event-dispatcher listener 接線點：XxxRecordWriterListener 等 listener 於 protected/config/main.php（或對應 module config）的 events/EventDispatcher 區塊註冊
dev4 opcache reset 前置：改動 view/PHP 後必先 docker exec -i pos_php sh -c 'kill -USR2 1'，否則 revalidate_freq=60 服務舊 bytecode
