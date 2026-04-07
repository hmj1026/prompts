# Yii 1.1 Framework Reference

**Framework 位置:** `/home/paul/projects/yii_framework/`

## DDD 呼叫路徑

```
Controller → $this->app()->{service}->fetchXxx() → Repository->forXxx()
```

- `$this->app()` 定義於 `protected/controllers/traits/DomainApplicable.php`

## PayTypeGroup 常數

完整常數值見 `.claude/docs/yii-constants.md`（按需查閱）。

## 其他注意事項

- MySQL collation 陷阱（strcasecmp vs strcmp）見 `testing.md`（同目錄）

## EILogger 日誌系統

> 完整使用要點見 `.claude/docs/eilogger.md`（按需查閱）
