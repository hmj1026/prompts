<?php
$version = "dev";
$destination = strlen($version) > 0 ? "zdpos_".$version : "zdpos";

$yii='../yii_framework/yii.php';
$config='../'.$destination.'/protected/config/dev3.php';

$uploadPath = dirname(__FILE__);

date_default_timezone_set("Asia/Taipei");
//defined('YII_DEBUG') or define('YII_DEBUG',true);
//defined('YII_TRACE_LEVEL') or define('YII_TRACE_LEVEL',3);
require_once($yii);


$app = Yii::createWebApplication($config);

Yii::import('ext.yiiexcel.YiiExcel', true);
Yii::registerAutoloader(array('YiiExcel', 'autoload'), true);
PHPExcel_Shared_ZipStreamWrapper::register();
if (ini_get('mbstring.func_overload') & 2) {
	throw new Exception('Multibyte function overloading in PHP must be disabled for string functions (2).');
}
PHPExcel_Shared_String::buildCharacterSets();

$app->run();

