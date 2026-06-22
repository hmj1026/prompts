---
paths:
  - "**/*.php"
---

# Yii 1.1 Framework (zdpos-specific)

Framework source: `~/projects/yii_framework/`.

## DDD Call Chain

```
Controller → $this->app()->{service}->fetchXxx() → Repository->forXxx()
```

`$this->app()` defined in `protected/controllers/traits/DomainApplicable.php`.

## Namespace Autoload

Entry: **project root** `setPathOfAlias.php` (not in `protected/`); required by `protected/config/{env}.php` before `return`. Mounts:

```php
Yii::setPathOfAlias('Infrastructure', __DIR__ . '/infrastructure/');
Yii::setPathOfAlias('Domain',         __DIR__ . '/domain/');
```

New classes auto-load when filename + namespace align. **Do not** touch `composer.json` (its only role is `autoload-dev` for `application\tests\`).

`class not found` triage: (1) case match (Linux is case-sensitive); (2) first namespace segment matches an alias; (3) the current env config actually requires `setPathOfAlias.php`.

## Bootstrap timing

`CApplication::__construct($config)` 載入時序（驗證自 `yii_framework/base/CApplication.php:127-155`）：

```
line 129: Yii::setApplication($this)        ← Yii::app() 此時起即可用
line 133: if (is_string($config))
              $config = require($config)    ← 觸發 require <merchant-config>.php
                                              → merchant config 第一行 require setPathOfAlias.php
                                              → setPathOfAlias.php 執行時 Yii::app() **已存在**
line 145: $this->preinit()
line 148: $this->initSystemHandlers()
line 149: $this->registerCoreComponents()   ← merge mode 註冊 db/cache/request 等核心 component
line 150: $this->configure($config)         ← merge mode 套用 merchant config['components']
line 152: $this->preloadComponents()
line 155: $this->init()
```

**含義 / 可利用點**：

- **`setPathOfAlias.php` 內 `Yii::app() !== null`**：可直接呼叫 `Yii::app()->setComponent($id, $instance)` 預註冊 infrastructure component（lazy registration，不立即 instantiate）。後續 `registerCoreComponents()` / `configure($config)` 走 merge mode，**不會覆寫**已 setComponent 的同名 component（除非 merchant config 內也有同名宣告）。
- **集中注入 SSOT**：22 個 merchant config 都會 require setPathOfAlias.php，因此在該檔內統一 setComponent 達到「0 個 merchant config 變動」的注入效果。實作範例：`infrastructure/Events/EventDispatcherBootstrap::register()` + `setPathOfAlias.php` 結尾 `zdpos_register_infrastructure_components(Yii::app())`。詳見 `docs/guides/event-dispatcher-cookbook.md`。
- **限制**：`preinit()` 之前 `Yii::app()->getComponent($id)` 會空跑（component 未 init），所以 setPathOfAlias.php 內**只能 setComponent，不能 getComponent**。實際 component init 在第一次有 caller 拿來用時才觸發。

**常見誤判**：「`Yii::app()` 在 setPathOfAlias.php 內是 null」是錯誤直覺 — Yii 1.1 在 construct 第一行就 setApplication，require config 在第三行才發生。

## PayTypeGroup Constants (`domain/Models/PayTypeGroup.php`)

No magic strings.

| Constant | Value |
|----------|-------|
| `THIRD_PARTY` | `'3rdParty'` |
| `MULTI_PAY` | `'multiPay'` |
| `TOTAL_PAY` | `'TotalPay'` |
| `TICKET` | `'ticket'` |

## Refs

- MySQL collation trap (`strcasecmp` vs `strcmp`) → `testing.md`
- EILogger usage → `.claude/docs/eilogger.md`
