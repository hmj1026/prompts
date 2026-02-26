# Prompt Reference / Yii Built-ins Priority

## Yii 1.x 內建函式優先策略（Context7 整理）
> Context7 參考來源：`/websites/yiiframework_doc_api_1_0`（https://context7.com/websites/yiiframework_doc_api_1_0）
> 本段依該來源整理，並套用本專案 `CLAUDE.md` 限制。

優先順序（由高到低）：
1. 優先用 Yii 內建能力（`Yii::app()`、`CActiveRecord`、`CDbCommand`、`CDbCriteria`、`CHtml`、`CJSON`）。
2. 內建能力無法滿足時，若專案內已有改寫/封裝方法，必須優先沿用既有改寫方法（避免平行實作）。
3. 若無既有改寫方法，再擴充現有 Domain/Infrastructure 類別。
4. 最後才考慮新增通用 helper（避免重複造輪子）。

## 常見需求對應
- 取參數：`Yii::app()->request->getPost()/getParam()/getQuery()`
  - 專案限制：避免直接讀 `$_POST`。
- DB 查詢：`Yii::app()->db->createCommand($sql)` + `bindValue()/bindParam()` + `queryRow()/queryAll()/queryScalar()/execute()`
  - 專案限制：一律使用參數綁定（prepared statement）。
- ActiveRecord：每個 AR 類別保留 `public static function model($className=__CLASS__)`
- 模型驗證：優先在 `rules()` 定義規則，搭配 `validate()` / `hasErrors()`。
- 條件組裝：優先 `CDbCriteria`（如 `addCondition()`、`addInCondition()`）。
- 安全輸出：畫面文字優先 `CHtml::encode()`。
- JSON 回應：優先 `CJSON::encode()`，輸出後 `Yii::app()->end()`。
- 表單/AJAX 驗證：優先 `CActiveForm::validate($model)`。
- CSRF：啟用 `request->enableCsrfValidation` 時，表單優先用 `CHtml::form()` / `CHtml::statefulForm()`（或 `CHtml::beginForm()`）產生 token。

## 最小對應範例（Yii 內建優先）
```php
public function actionSearch()
{
    $keyword = Yii::app()->request->getQuery('keyword', '');

    $criteria = new CDbCriteria();
    if ($keyword !== '') {
        $criteria->addCondition('name LIKE :keyword');
        $criteria->params[':keyword'] = '%' . $keyword . '%';
    }

    $rows = Yii::app()->db->createCommand()
        ->select('id, name')
        ->from('data_customer')
        ->where($criteria->condition, $criteria->params)
        ->queryAll();

    echo CJSON::encode([
        'success' => true,
        'data' => $rows,
    ]);
    Yii::app()->end();
}
```
