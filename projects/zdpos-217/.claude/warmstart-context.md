DDD layers: protected/ (Yii Controller/Model/View) | domain/ (Service/Repository contracts) | infrastructure/ (DB / cache / external API)
Yii 1.1 framework: ~/projects/yii_framework/ | Docker: pos_php (PHP 5.6 + Yii) / pos_mysql (MySQL 5.7)
PHPUnit cmd: docker exec -i -w /var/www/www.posdev/zdpos-217 pos_php phpunit -c protected/tests/phpunit.xml [--testsuite unit|integration]
