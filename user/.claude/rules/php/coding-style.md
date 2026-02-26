> This file extends [common/coding-style.md](../common/coding-style.md) with PHP specific content.

# PHP Coding Style

## PHP 5.6 Compatibility (Critical Hard Limits)

### Type Declarations - FORBIDDEN
```php
// ❌ WRONG - PHP 5.6 does not support type hints
function processOrder(int $orderId): string {
    return "Order: " . $orderId;
}

// ✅ CORRECT - Use PHPDoc annotations
/**
 * Process an order
 * @param int $orderId Order identifier
 * @return string Order status message
 */
function processOrder($orderId) {
    return "Order: " . $orderId;
}
```

### Null Coalescing Operator - FORBIDDEN
```php
// ❌ WRONG - Null coalescing (??) not available in PHP 5.6
$status = $order->status ?? 'pending';

// ✅ CORRECT - Use ternary or isset()
$status = isset($order->status) ? $order->status : 'pending';
```

### Array Syntax
```php
// ❌ WRONG
$data = array('key' => 'value');

// ✅ CORRECT - Use modern array syntax
$data = ['key' => 'value'];
```

## Input Access (Framework Required)

```php
// ❌ WRONG - Direct $_POST access
$username = $_POST['username'];

// ✅ CORRECT - Use Yii framework
$username = Yii::app()->request->getPost('username');
$requestData = Yii::app()->request->getPost(); // All POST data
```

## Immutability Pattern

```php
// ❌ WRONG - Mutating original array
function addDiscount(&$items, $discount) {
    foreach ($items as &$item) {
        $item['price'] -= $discount;
    }
    return $items;
}

// ✅ CORRECT - Create new array without mutation
function addDiscount($items, $discount) {
    $discountedItems = [];
    foreach ($items as $item) {
        $newItem = $item;
        $newItem['price'] -= $discount;
        $discountedItems[] = $newItem;
    }
    return $discountedItems;
}
```

## Yii 1.1 Conventions

### Model Definition (ActiveRecord)
```php
class Order extends CActiveRecord {
    public static function model($className = __CLASS__) {
        return parent::model($className);
    }

    public function tableName() {
        return 'order';
    }

    public function rules() {
        return [
            ['orderId, customerId, status', 'required'],
            ['orderId', 'unique'],
        ];
    }
}
```

### Database Access - PDO Prepared Statements (MANDATORY)

```php
// ❌ WRONG - SQL Injection vulnerability
$sql = "SELECT * FROM order WHERE orderId = " . $_GET['orderId'];
$result = Yii::app()->db->createCommand($sql)->queryAll();

// ✅ CORRECT - Parameterized query
$sql = "SELECT * FROM order WHERE orderId = :orderId";
$result = Yii::app()->db->createCommand($sql)
    ->bindParam(':orderId', $orderId, PDO::PARAM_INT)
    ->queryAll();

// ✅ ALSO CORRECT - Using Model find methods
$order = Order::model()->findByPk($orderId);
$orders = Order::model()->findAll('status = :status', [':status' => $status]);
```

### Controller & Action Naming
```php
// File: protected/controllers/OrderController.php
class OrderController extends Controller {
    public function actionIndex() { }
    public function actionView() { }
    public function actionCreate() { }
    public function actionUpdate() { }
    public function actionDelete() { }
}
```

## File Organization

Max file size: **800 lines**
Typical module structure:

```
protected/
├── models/           # ActiveRecord classes (200-400 lines each)
├── controllers/      # Controllers (200-400 lines each)
├── services/         # Business logic (200-400 lines each)
├── validators/       # Custom validators
├── helpers/          # Utility functions
├── modules/          # Feature modules
└── components/       # Reusable components
```

## Code Quality Checklist

Before marking work complete:
- [ ] All PHP 5.6 compatibility checks passed
- [ ] No direct $_POST/$_GET access (use framework)
- [ ] All PDO queries use prepared statements
- [ ] No type hints or return type declarations
- [ ] All arrays use `[]` syntax
- [ ] Functions < 50 lines
- [ ] Files < 800 lines
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation of input parameters (unless explicitly documented)
- [ ] ActiveRecord models have `public static function model()`

## Error Handling

```php
// ❌ WRONG - Silent failure
if ($order = Order::model()->findByPk($orderId)) {
    // ...
}

// ✅ CORRECT - Explicit error handling
$order = Order::model()->findByPk($orderId);
if (!$order) {
    throw new CHttpException(404, 'Order not found.');
}
// Process $order
```

## PHPDoc Standards

All public methods require PHPDoc:

```php
/**
 * Calculate order total with tax and discounts.
 *
 * @param Order $order The order to process
 * @param float $taxRate Tax rate (0.05 = 5%)
 * @return float Total order amount
 * @throws InvalidArgumentException if $taxRate < 0
 */
public function calculateTotal(Order $order, $taxRate) {
    if ($taxRate < 0) {
        throw new InvalidArgumentException('Tax rate cannot be negative');
    }
    // ... implementation
}
```
