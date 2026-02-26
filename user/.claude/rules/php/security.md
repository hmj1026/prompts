> This file extends [common/security.md](../common/security.md) with PHP specific content.

# PHP Security Guidelines

## Critical Security Checklist

Before ANY commit of PHP code:

- [ ] **SQL Injection** - All DB queries use PDO prepared statements
- [ ] **Authentication/Authorization** - Controllers check `Yii::app()->user->isGuest`
- [ ] **CSRF Protection** - Forms include CSRF token (Yii default enabled)
- [ ] **XSS Prevention** - All user data output escaped with `CHtml::encode()`
- [ ] **Hardcoded Secrets** - No API keys, passwords, or tokens in code
- [ ] **Input Validation** - All user inputs validated before processing
- [ ] **Session Security** - HTTPS enforced, secure cookie flags set
- [ ] **File Upload** - Whitelist extensions, validate MIME types, store outside webroot

## SQL Injection Prevention (CRITICAL)

### ❌ WRONG - Direct concatenation
```php
$orderId = $_GET['orderId']; // NEVER trust user input
$sql = "SELECT * FROM order WHERE orderId = " . $orderId;
$result = Yii::app()->db->createCommand($sql)->queryAll();
```

**Vulnerability:** Attacker can input `1 OR 1=1` to dump entire database.

### ✅ CORRECT - PDO Prepared Statements
```php
$orderId = Yii::app()->request->getQuery('orderId');
$sql = "SELECT * FROM order WHERE orderId = :orderId";
$result = Yii::app()->db->createCommand($sql)
    ->bindParam(':orderId', $orderId, PDO::PARAM_INT)
    ->queryAll();
```

### ✅ ALSO CORRECT - ActiveRecord with Parameters
```php
$orderId = Yii::app()->request->getQuery('orderId');
$order = Order::model()->findByPk($orderId); // Safe - uses prepared statement internally

// Or with custom condition
$criteria = new CDbCriteria();
$criteria->compare('status', $status); // Safe - uses parameter binding
$orders = Order::model()->findAll($criteria);
```

### ✅ ALSO CORRECT - Yii::app()->db with bindValue
```php
$status = Yii::app()->request->getPost('status');
$result = Yii::app()->db->createCommand()
    ->select('*')
    ->from('order')
    ->where('status = :status', [':status' => $status])
    ->queryAll();
```

## Cross-Site Scripting (XSS) Prevention

### ❌ WRONG - Direct output of user data
```php
<?php
$name = $_GET['name'];
echo "Hello, " . $name; // Attacker can inject <script> tags
?>
```

### ✅ CORRECT - HTML escape all user data
```php
<?php
$name = Yii::app()->request->getQuery('name');
echo "Hello, " . CHtml::encode($name); // Safe - special chars escaped
?>

<!-- Render complex HTML -->
<?php echo CHtml::encode($userComment); ?>

<!-- In Yii widgets -->
<?php $this->widget('zii.widgets.CListView', [
    'dataProvider' => $dataProvider,
    'itemView' => '_order', // View escapes variables
]); ?>
```

### Content Security Policy

Add to protected/config/main.php:
```php
'components' => [
    'request' => [
        'class' => 'CHttpRequest',
        'secureSchemePrefix' => 'https',
    ],
],

// In controller actions that output user data
public function actionView() {
    Yii::app()->clientScript->registerMetaTag(
        "default-src 'self'; script-src 'self' 'unsafe-inline'",
        'Content-Security-Policy'
    );
}
```

## Authentication & Authorization

### ❌ WRONG - Missing auth check
```php
public function actionDelete() {
    $orderId = Yii::app()->request->getQuery('orderId');
    Order::model()->deleteByPk($orderId);
    echo "Deleted";
}
```

### ✅ CORRECT - Auth check required
```php
public function actionDelete() {
    // Check if user is logged in
    if (Yii::app()->user->isGuest) {
        throw new CHttpException(403, 'Access denied');
    }

    // Check user permissions
    $orderId = Yii::app()->request->getQuery('orderId');
    $order = Order::model()->findByPk($orderId);

    if (!$order) {
        throw new CHttpException(404, 'Order not found');
    }

    // Check ownership (user can only delete own orders)
    if ($order->customerId != Yii::app()->user->id) {
        throw new CHttpException(403, 'Cannot delete other users orders');
    }

    $order->delete();
    echo "Order deleted";
}
```

## CSRF Protection

Yii 1.1 has CSRF protection built-in (enabled by default).

### Enable CSRF Validation
```php
// protected/config/main.php
'components' => [
    'request' => [
        'class' => 'CHttpRequest',
        'enableCsrfValidation' => true, // Enabled by default
        'csrfTokenName' => 'YII_CSRF_TOKEN',
    ],
],
```

### Form Includes CSRF Token
```php
<!-- In views/order/create.php -->
<?php $form = $this->beginWidget('CActiveForm', [
    'id' => 'order-form',
    'enableClientValidation' => true,
]); ?>

<!-- CSRF token automatically included by beginWidget -->
<input type="hidden" name="<?php echo Yii::app()->request->csrfTokenName; ?>"
       value="<?php echo Yii::app()->request->csrfToken; ?>" />

<!-- Or use Yii helper -->
<?php echo CHtml::hiddenField(Yii::app()->request->csrfTokenName, Yii::app()->request->csrfToken); ?>

<?php $this->endWidget(); ?>
```

## Input Validation

### ❌ WRONG - No validation
```php
$email = $_POST['email'];
$order = new Order();
$order->email = $email;
$order->save();
```

### ✅ CORRECT - Validate input
```php
$email = Yii::app()->request->getPost('email');
$order = new Order();
$order->email = $email;

// Model validates rules before save
if ($order->validate()) {
    $order->save();
} else {
    // Handle validation errors
    foreach ($order->getErrors() as $attribute => $errors) {
        echo $attribute . ': ' . implode(', ', $errors);
    }
}
```

### Model Validation Rules
```php
class Order extends CActiveRecord {

    public function rules() {
        return [
            // Email validation
            ['email', 'email'],

            // Required fields
            ['customerId, status', 'required'],

            // Length validation
            ['comments', 'length', 'max' => 500],

            // Numeric validation
            ['orderId', 'numerical', 'integerOnly' => true],

            // Custom validator
            ['status', 'ext.validators.OrderStatusValidator'],

            // Whitelist validation
            ['status', 'in', 'range' => ['pending', 'confirmed', 'shipped']],
        ];
    }
}
```

## Secret Management

### ❌ WRONG - Hardcoded secrets
```php
class PaymentGateway {
    private $apiKey = 'sk_live_abc123def456'; // NEVER do this
}
```

### ✅ CORRECT - Environment variables
```php
class PaymentGateway {
    private $apiKey;

    public function __construct() {
        $this->apiKey = getenv('STRIPE_API_KEY');

        if (!$this->apiKey) {
            throw new Exception('STRIPE_API_KEY environment variable not set');
        }
    }
}

// In protected/config/main.php
'components' => [
    'paymentGateway' => [
        'class' => 'application.gateways.PaymentGateway',
        // No hardcoded keys
    ],
],
```

### .env File (Git-ignored)
```bash
# .env (add to .gitignore)
STRIPE_API_KEY=sk_live_xxx...
DATABASE_PASSWORD=...
JWT_SECRET=...
```

## File Upload Security

### ❌ WRONG - No validation
```php
$file = $_FILES['attachment'];
move_uploaded_file($file['tmp_name'], '/var/www/uploads/' . $file['name']);
```

### ✅ CORRECT - Validate and secure
```php
$file = Yii::app()->request->getFiles('attachment');

if (!$file) {
    throw new CHttpException(400, 'No file uploaded');
}

// Whitelist allowed extensions
$allowedExtensions = ['pdf', 'doc', 'docx', 'xls'];
$fileExt = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

if (!in_array($fileExt, $allowedExtensions)) {
    throw new CHttpException(400, 'Invalid file type');
}

// Check file size
$maxSize = 5 * 1024 * 1024; // 5MB
if ($file['size'] > $maxSize) {
    throw new CHttpException(400, 'File too large');
}

// Generate safe filename
$safeFilename = md5(uniqid() . $file['name']) . '.' . $fileExt;

// Store outside webroot
$uploadDir = Yii::app()->basePath . '/uploads/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0700, true);
}

move_uploaded_file($file['tmp_name'], $uploadDir . $safeFilename);
```

## Session Security

### Configure Secure Cookies
```php
// protected/config/main.php
'components' => [
    'session' => [
        'class' => 'CHttpSession',
        'sessionName' => 'MYAPP_SID',
        'autoStart' => true,
        // Secure cookie settings
        'cookieParams' => [
            'httponly' => true,  // Prevent JavaScript access
            'secure' => true,    // HTTPS only
            'samesite' => 'Lax', // CSRF protection (PHP 7.3+ equivalent via headers)
        ],
    ],
],
```

### Set Security Headers
```php
// In protected/components/Controller.php base controller
public function init() {
    parent::init();

    // Prevent clickjacking
    header('X-Frame-Options: SAMEORIGIN');

    // Prevent MIME type sniffing
    header('X-Content-Type-Options: nosniff');

    // Enable XSS protection in older browsers
    header('X-XSS-Protection: 1; mode=block');

    // Enforce HTTPS
    if (!Yii::app()->request->isSecureConnection && YII_ENV === 'production') {
        header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
    }
}
```

## Rate Limiting

```php
class OrderController extends Controller {

    public function filters() {
        return [
            ['ext.components.RateLimitFilter - delete,create'],
        ];
    }

    public function actionCreate() {
        // Rate limited to prevent abuse
    }
}

// Implement rate limiter
class RateLimitFilter extends CFilter {

    public $limit = 10; // Max 10 requests
    public $window = 3600; // Per hour

    protected function preFilter($filterChain) {
        $userId = Yii::app()->user->id;
        $action = $filterChain->action->id;
        $key = "rate_limit:{$userId}:{$action}";

        $count = Yii::app()->cache->get($key);
        if ($count === false) {
            $count = 0;
        }

        if ($count >= $this->limit) {
            throw new CHttpException(429, 'Rate limit exceeded');
        }

        Yii::app()->cache->set($key, $count + 1, $this->window);
        return true;
    }
}
```

## Security Response Protocol

If security issue found:

1. **STOP immediately** - Do not commit
2. **Use security-reviewer agent** - Analyze and fix
3. **Check for similar issues** - Search codebase for same pattern
4. **Rotate exposed secrets** - If any credentials exposed
5. **Document fix** - Update security guidelines if needed
