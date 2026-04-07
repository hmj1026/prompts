> This file extends [common/testing.md](../common/testing.md) with PHP specific content.

# PHP Testing

## Test Coverage: 80% Minimum

**Required test types:**
1. **Unit Tests** - Model methods, validators, helpers
2. **Integration Tests** - Controllers, database operations, API responses
3. **E2E Tests** - Critical business flows (order creation, payment, etc.)

## PHPUnit Framework

### Test File Organization

```
protected/tests/
├── unit/
│   ├── models/          # Model tests
│   ├── validators/      # Validator tests
│   ├── services/        # Service/business logic tests
│   └── helpers/         # Helper function tests
├── integration/
│   ├── controllers/     # Controller tests
│   ├── api/             # API endpoint tests
│   └── database/        # Database operation tests
└── fixtures/            # Test data, setup/teardown
```

### Running Tests

```bash
# Windows Git Bash format (required for this project)
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/unit

docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit protected/tests/integration/OrderControllerTest.php

docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit --coverage-html protected/tests/coverage protected/tests
```

## Unit Test Pattern

```php
<?php
class OrderModelTest extends CTestCase {

    public function setUp() {
        parent::setUp();
        $this->order = new Order();
    }

    public function tearDown() {
        parent::tearDown();
    }

    /**
     * Test order total calculation with tax.
     */
    public function testCalculateTotalWithTax() {
        $this->order->subtotal = 100;
        $this->order->tax_rate = 0.1; // 10%

        $total = $this->order->calculateTotal();

        $this->assertEquals(110, $total);
    }

    /**
     * Test invalid tax rate throws exception.
     */
    public function testCalculateTotalInvalidTaxRateThrows() {
        $this->order->subtotal = 100;
        $this->order->tax_rate = -0.1; // Invalid

        $this->setExpectedException('InvalidArgumentException');
        $this->order->calculateTotal();
    }

    /**
     * Test order status transitions.
     * @dataProvider statusTransitionProvider
     */
    public function testStatusTransition($fromStatus, $toStatus, $isValid) {
        $this->order->status = $fromStatus;
        $result = $this->order->changeStatus($toStatus);
        $this->assertEquals($isValid, $result);
    }

    public function statusTransitionProvider() {
        return [
            ['pending', 'confirmed', true],
            ['confirmed', 'shipped', true],
            ['shipped', 'pending', false],
        ];
    }
}
```

## Integration Test Pattern

```php
<?php
class OrderControllerTest extends CWebTestCase {

    public function setUp() {
        parent::setUp();
        // Clear test data
        Order::model()->deleteAll();
    }

    /**
     * Test order creation endpoint returns order ID.
     */
    public function testCreateOrderAction() {
        $postData = [
            'customerId' => 123,
            'items' => [
                ['productId' => 1, 'quantity' => 2],
                ['productId' => 2, 'quantity' => 1],
            ],
        ];

        $this->open('/order/create');
        $this->post($postData);

        $this->assertResponseCode(200);
        $this->assertTextPresent('Order created successfully');

        $order = Order::model()->findAll('customerId = :cid', [':cid' => 123]);
        $this->assertEquals(1, count($order));
    }

    /**
     * Test invalid data returns validation errors.
     */
    public function testCreateOrderValidationError() {
        $postData = [
            'customerId' => null, // Missing required field
            'items' => [],
        ];

        $this->open('/order/create');
        $this->post($postData);

        $this->assertResponseCode(400);
        $this->assertTextPresent('customerId is required');
    }
}
```

## Mock & Fixture Pattern

```php
<?php
class OrderServiceTest extends CTestCase {

    private $mockPaymentGateway;
    private $orderService;

    public function setUp() {
        parent::setUp();

        // Mock external dependency
        $this->mockPaymentGateway = $this->getMock('PaymentGateway');
        $this->orderService = new OrderService($this->mockPaymentGateway);
    }

    public function testProcessPaymentSuccess() {
        // Setup mock expectations
        $this->mockPaymentGateway->expects($this->once())
            ->method('charge')
            ->with($this->equalTo(100.00))
            ->will($this->returnValue(['success' => true, 'txId' => 'tx123']));

        $result = $this->orderService->processPayment(100.00);

        $this->assertTrue($result['success']);
        $this->assertEquals('tx123', $result['txId']);
    }

    public function testProcessPaymentFailure() {
        // Mock failure response
        $this->mockPaymentGateway->expects($this->once())
            ->method('charge')
            ->will($this->throwException(new Exception('Payment declined')));

        $this->setExpectedException('Exception', 'Payment declined');
        $this->orderService->processPayment(100.00);
    }
}
```

## TDD Workflow (Red → Green → Refactor)

### Step 1: Write Failing Test (RED)
```php
public function testAddDiscountToOrder() {
    $order = new Order();
    $order->subtotal = 100;

    // This method doesn't exist yet - test fails
    $order->applyDiscount(10); // $10 discount

    $this->assertEquals(90, $order->getTotal());
}
```

### Step 2: Minimal Implementation (GREEN)
```php
// In Order model
public function applyDiscount($amount) {
    $this->discount = $amount;
}

public function getTotal() {
    return $this->subtotal - $this->discount;
}
```

### Step 3: Refactor (IMPROVE)
```php
// Improve validation and error handling
public function applyDiscount($amount) {
    if ($amount < 0) {
        throw new InvalidArgumentException('Discount cannot be negative');
    }
    if ($amount > $this->subtotal) {
        throw new InvalidArgumentException('Discount exceeds order total');
    }
    $this->discount = $amount;
}

public function getTotal() {
    return $this->subtotal - $this->discount;
}
```

## Coverage Tools

```bash
# Generate coverage report
docker exec -w //var/www/www.posdev/zdpos_dev pos_php phpunit \
    --coverage-html protected/tests/coverage/html \
    --coverage-text \
    protected/tests

# View coverage summary
cat protected/tests/coverage/html/index.html
```

## Database Testing

Use transactions to isolate test data:

```php
public function testOrderSaveToDatabase() {
    $transaction = Yii::app()->db->beginTransaction();

    try {
        $order = new Order();
        $order->customerId = 123;
        $order->status = 'pending';
        $this->assertTrue($order->save());

        $loaded = Order::model()->findByPk($order->orderId);
        $this->assertNotNull($loaded);
        $this->assertEquals(123, $loaded->customerId);
    } finally {
        $transaction->rollback(); // Cleanup
    }
}
```

## Test Isolation

- [ ] Each test starts with clean state (setUp)
- [ ] Each test cleans after itself (tearDown)
- [ ] No test depends on another test's output
- [ ] Mocks don't leak between tests
- [ ] Database transactions rolled back after each test
