# Prompt Reference / PHP 5.6 Examples

## 典型範例
範例僅供風格與結構參考，以下示範為「PHP 5.6 + 專案限制對應版」。

### Controller Action（PHP 5.6 + Request Wrapper + Early Return）
```php
public function actionLookupTaxTitle()
{
    $taxId = Yii::app()->request->getPost('tax_id', '');

    if ($taxId === '') {
        echo CJSON::encode([
            'success' => false,
            'msg' => 'tax_id is required',
        ]);
        Yii::app()->end();
    }

    try {
        $service = new MaintainStoreService(new MaintainStoreRepository());
        $result = $service->lookupTaxTitle($taxId);

        echo CJSON::encode([
            'success' => true,
            'data' => $result,
        ]);
    } catch (Exception $e) {
        echo CJSON::encode([
            'success' => false,
            'msg' => $e->getMessage(),
        ]);
    }

    Yii::app()->end();
}
```

### Domain Service（PHPDoc 型別，不使用 scalar type hints）
```php
class MaintainStoreService
{
    /** @var MaintainStoreRepository */
    private $repository;

    /**
     * @param MaintainStoreRepository $repository
     */
    public function __construct($repository)
    {
        $this->repository = $repository;
    }

    /**
     * @param string $taxId
     * @return array
     */
    public function lookupTaxTitle($taxId)
    {
        if ($taxId === '') {
            throw new InvalidArgumentException('tax_id is required');
        }

        return $this->repository->findTaxTitleByTaxId($taxId);
    }
}
```

### Repository（Prepared Statement / Parameter Binding）
```php
class MaintainStoreRepository extends EntityRepository
{
    /**
     * @param string $taxId
     * @return array
     */
    public function findTaxTitleByTaxId($taxId)
    {
        $sql = "SELECT tax_id, title FROM data_tax_title WHERE tax_id = :tax_id LIMIT 1";

        $row = $this->createCommand($sql)->queryRow(true, [
            ':tax_id' => $taxId,
        ]);

        return $row ? $row : [];
    }
}
```

### ActiveRecord（Yii 1.1 必備 `model()` 樣板）
```php
class DataTaxTitle extends CActiveRecord
{
    public function tableName()
    {
        return 'data_tax_title';
    }

    public static function model($className = __CLASS__)
    {
        return parent::model($className);
    }
}
```

### Frontend（禁用 `$.ajax`/`fetch`/`axios`）
```javascript
// 使用 POS.list.ajaxPromise 呼叫後端
async function lookupTaxTitle(taxId) {
    if (!taxId) {
        return { success: false, msg: 'tax_id is required' };
    }

    try {
        const response = await POS.list.ajaxPromise('lookupTaxTitle', {
            tax_id: taxId
        });
        return response;
    } catch (error) {
        return {
            success: false,
            msg: error && error.message ? error.message : 'Lookup failed'
        };
    }
}
```
