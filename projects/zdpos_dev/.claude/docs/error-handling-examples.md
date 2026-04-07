# PHP Error Handling Examples (從 error-handling-patterns.md 提取)

> 本檔為 always-on rules 瘦身後的 code example 參考，按需查閱。

## Domain / Service 層

```php
public function processOrder($orderId)
{
    $order = $this->orderRepo->findById($orderId);
    if (!$order) {
        throw new Exception('訂單不存在: ' . $orderId);
    }
    if ($order->status !== 'pending') {
        throw new Exception('訂單狀態不允許操作: ' . $order->status);
    }
    // ... 業務邏輯
}
```

## Repository 層

```php
public function save($data)
{
    try {
        // ... DB 操作
    } catch (CDbException $e) {
        EILogger::slog([
            'method'  => __METHOD__,
            'message' => 'DB 寫入失敗',
            'error'   => $e->getMessage(),
            'data'    => $data,
        ], 'RepositoryError');
        throw $e;
    }
}
```

## Controller 層（AJAX）

```php
public function actionUpdate()
{
    try {
        $result = $this->app()->orderService->update($data);
        $this->json(['success' => true, 'data' => $result, 'message' => '']);
    } catch (Exception $e) {
        EILogger::slog([
            'method'  => __METHOD__,
            'error'   => $e->getMessage(),
        ], 'ActionError');
        $this->error($e->getMessage());
    }
}
```

## 標準 JSON 回應

```php
// 成功
$this->json(['success' => true, 'data' => $result, 'message' => '']);

// 失敗
$this->error('操作失敗原因');
```
