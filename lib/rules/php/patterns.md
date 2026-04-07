> This file extends [common/patterns.md](../common/patterns.md) with PHP specific content.

# PHP Design Patterns

## Repository Pattern (Yii 1.1)

Encapsulate data access behind a consistent interface. Yii ActiveRecord already implements repository-like behavior.

### Pattern Definition

```php
/**
 * Interface for Order repository operations
 */
interface IOrderRepository {
    /**
     * @param int $orderId
     * @return Order|null
     */
    public function findById($orderId);

    /**
     * @return Order[]
     */
    public function findAll();

    /**
     * @param array $criteria
     * @return Order[]
     */
    public function findByCriteria($criteria);

    /**
     * @param Order $order
     * @return bool
     */
    public function save(Order $order);

    /**
     * @param Order $order
     * @return bool
     */
    public function delete(Order $order);
}

/**
 * Yii ActiveRecord implementation of order repository
 */
class OrderRepository implements IOrderRepository {

    public function findById($orderId) {
        return Order::model()->findByPk($orderId);
    }

    public function findAll() {
        return Order::model()->findAll();
    }

    public function findByCriteria($criteria) {
        $sql = [];
        $params = [];

        if (isset($criteria['status'])) {
            $sql[] = 'status = :status';
            $params[':status'] = $criteria['status'];
        }

        if (isset($criteria['customerId'])) {
            $sql[] = 'customerId = :customerId';
            $params[':customerId'] = $criteria['customerId'];
        }

        $condition = implode(' AND ', $sql);
        return Order::model()->findAll($condition, $params);
    }

    public function save(Order $order) {
        return $order->save();
    }

    public function delete(Order $order) {
        return $order->delete();
    }
}
```

### Usage Example

```php
class OrderService {

    private $orderRepository;

    public function __construct(IOrderRepository $orderRepository) {
        $this->orderRepository = $orderRepository;
    }

    public function getCustomerOrders($customerId) {
        $criteria = ['customerId' => $customerId];
        return $this->orderRepository->findByCriteria($criteria);
    }

    public function processOrder(Order $order) {
        // Business logic here
        return $this->orderRepository->save($order);
    }
}

// In controller
$repository = new OrderRepository();
$service = new OrderService($repository);
$orders = $service->getCustomerOrders(123);
```

## Service Layer Pattern (Business Logic)

Separate business logic from controllers and models.

```php
/**
 * Order processing service encapsulates all order-related logic
 */
class OrderProcessingService {

    private $orderRepository;
    private $paymentGateway;
    private $notificationService;

    public function __construct(
        IOrderRepository $orderRepository,
        PaymentGatewayInterface $paymentGateway,
        NotificationServiceInterface $notificationService
    ) {
        $this->orderRepository = $orderRepository;
        $this->paymentGateway = $paymentGateway;
        $this->notificationService = $notificationService;
    }

    /**
     * Create and process a new order
     * @param int $customerId
     * @param array $items
     * @return Order
     * @throws InvalidArgumentException
     * @throws PaymentException
     */
    public function createOrder($customerId, $items) {
        if (empty($items)) {
            throw new InvalidArgumentException('Order must have at least one item');
        }

        $order = new Order();
        $order->customerId = $customerId;
        $order->status = Order::STATUS_PENDING;

        if (!$this->orderRepository->save($order)) {
            throw new Exception('Failed to create order');
        }

        try {
            $total = $this->calculateOrderTotal($order, $items);
            $this->paymentGateway->charge($total);
            $order->status = Order::STATUS_CONFIRMED;
            $this->orderRepository->save($order);

            $this->notificationService->notifyCustomer($customerId, 'Order confirmed');

            return $order;
        } catch (PaymentException $e) {
            $this->orderRepository->delete($order);
            throw $e;
        }
    }

    /**
     * Calculate total with tax and discounts
     * @param Order $order
     * @param array $items
     * @return float
     */
    private function calculateOrderTotal(Order $order, $items) {
        $subtotal = 0;
        foreach ($items as $item) {
            $subtotal += $item['price'] * $item['quantity'];
        }
        $tax = $subtotal * Order::TAX_RATE;
        return $subtotal + $tax;
    }
}
```

## Validator Pattern (Custom Validation)

```php
/**
 * Custom validator for order status transitions
 */
class OrderStatusValidator extends CValidator {

    protected function validateAttribute($object, $attribute) {
        $value = $object->$attribute;
        $currentStatus = $object->getOldAttribute('status');

        $validTransitions = $this->getValidTransitions($currentStatus);

        if (!in_array($value, $validTransitions)) {
            $this->addError($object, $attribute,
                'Cannot transition from ' . $currentStatus . ' to ' . $value);
        }
    }

    private function getValidTransitions($fromStatus) {
        $transitions = [
            Order::STATUS_PENDING => [Order::STATUS_CONFIRMED],
            Order::STATUS_CONFIRMED => [Order::STATUS_SHIPPED],
            Order::STATUS_SHIPPED => [Order::STATUS_DELIVERED],
            Order::STATUS_DELIVERED => [],
        ];

        return isset($transitions[$fromStatus]) ? $transitions[$fromStatus] : [];
    }
}

// Usage in Model
public function rules() {
    return [
        ['status', 'ext.validators.OrderStatusValidator'],
    ];
}
```

## API Response Format (DDD-inspired Envelope)

Consistent response structure for all endpoints:

```php
/**
 * API response wrapper
 */
class ApiResponse {

    private $success;
    private $data;
    private $message;
    private $metadata;

    public function __construct($success, $data = null, $message = null, $metadata = null) {
        $this->success = $success;
        $this->data = $data;
        $this->message = $message;
        $this->metadata = $metadata;
    }

    public function toArray() {
        return [
            'success' => $this->success,
            'data' => $this->data,
            'message' => $this->message,
            'metadata' => $this->metadata,
        ];
    }
}

// Usage in Controller
public function actionGetOrder() {
    $orderId = Yii::app()->request->getQuery('orderId');

    try {
        $order = Order::model()->findByPk($orderId);
        if (!$order) {
            return $this->renderJson(
                new ApiResponse(false, null, 'Order not found')
            );
        }

        return $this->renderJson(
            new ApiResponse(true, $order->attributes, 'Order retrieved successfully')
        );
    } catch (Exception $e) {
        return $this->renderJson(
            new ApiResponse(false, null, 'Error: ' . $e->getMessage())
        );
    }
}
```

## Pagination Pattern

```php
public function actionListOrders() {
    $page = Yii::app()->request->getQuery('page', 1);
    $pageSize = Yii::app()->request->getQuery('pageSize', 20);

    $criteria = new CDbCriteria();
    $criteria->order = 'createdAt DESC';

    $count = Order::model()->count($criteria);
    $offset = ($page - 1) * $pageSize;

    $orders = Order::model()->findAll($criteria);

    return $this->renderJson(
        new ApiResponse(true, $orders, 'Orders retrieved', [
            'total' => $count,
            'page' => $page,
            'pageSize' => $pageSize,
            'totalPages' => ceil($count / $pageSize),
        ])
    );
}
```

## Immutability in Data Objects

```php
/**
 * Immutable OrderLine - once created, cannot be modified
 */
class OrderLine {

    private $productId;
    private $quantity;
    private $unitPrice;

    public function __construct($productId, $quantity, $unitPrice) {
        $this->productId = $productId;
        $this->quantity = $quantity;
        $this->unitPrice = $unitPrice;
    }

    public function getProductId() {
        return $this->productId;
    }

    public function getQuantity() {
        return $this->quantity;
    }

    public function getUnitPrice() {
        return $this->unitPrice;
    }

    public function getTotal() {
        return $this->quantity * $this->unitPrice;
    }

    /**
     * Create new instance with updated quantity
     * (original remains unchanged)
     */
    public function withQuantity($newQuantity) {
        return new OrderLine($this->productId, $newQuantity, $this->unitPrice);
    }
}
```

## Dependency Injection (Yii 1.1)

```php
class OrderController extends Controller {

    private $orderService;
    private $paymentGateway;

    /**
     * Constructor for dependency injection
     */
    public function __construct($id, $module = null) {
        parent::__construct($id, $module);

        $this->orderService = Yii::app()->getComponent('orderService');
        $this->paymentGateway = Yii::app()->getComponent('paymentGateway');
    }

    public function actionCreate() {
        $postData = Yii::app()->request->getPost();
        $order = $this->orderService->createOrder($postData);
        // ...
    }
}

// In config/main.php
'components' => [
    'orderService' => [
        'class' => 'application.services.OrderProcessingService',
    ],
    'paymentGateway' => [
        'class' => 'application.gateways.StripePaymentGateway',
    ],
],
```
