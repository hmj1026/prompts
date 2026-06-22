---
paths:
  - "**/*.php"
---

# PHP Patterns (zdpos-specific)

> Extends `~/.claude/rules/common/patterns.md`. Yii 1.1 + DDD layering.

## Repository / Service

Inject `IXxxRepository` into Domain Service (not AR model directly). Service Layer owns transaction / validation / external API / rollback.

## DB Query Layering (SQL location SSOT)

1. **Builder priority**: prefer `Infrastructure\Database\Query\Builder` via `$repo->queryBuilder()->where()->get()/first()/value()/count()/update()`; fall back to Yii `createCommand()` only when the toolkit doesn't fit.
2. **Location**: all SQL lives in Repository. Controller / Domain service / trait SHALL NOT call `Yii::app()->db->createCommand()` directly or build SQL strings.
3. **Naming**: business semantics + explicit required columns (`createWeatherContext($storeNo, ...)`). Forbidden: `insertRow($row)` / `updateBy($where, $set)` / `executeRaw($sql)`.
4. **Migration cadence**: new code follows 1+2 immediately; existing inline SQL only pushed down when its section is being modified.
5. **No mirror-existing escape hatch**: neighbor using `createCommand()` is not justification — create a **V2 parallel method** with `queryBuilder()` if upgrading is impractical, and annotate the legacy method `@see xxxV2`.

Toolkit prerequisite (unfamiliarity is not a fallback reason): read `docs/guides/query-toolkit-cookbook.md` + `docs/guides/query-toolkit-migration-guide.md`. Date helpers (`BuildsDateWheres` trait): `->whereDate('col', '>=|<=', 'YYYY-MM-DD')`. Spec: `infrastructure/CLAUDE.md` "Database Query Toolkit".

## Repository Discovery Gate

Before designing any new DB query:

```bash
grep -rl "<target_table>" infrastructure/Repositories/
# fallback: cx overview infrastructure/Repositories/
```

| Result | Action |
|---|---|
| Repository found | Add new method via `queryBuilder()`. Never in Controller. |
| Not found | Create `XxxRepository extends EntityRepository` in `infrastructure/Repositories/`. Never in Controller. |

`EntityRepository::queryBuilder()` returns a pre-configured `Builder`. Legacy `createCommand()` in a Controller is debt; presence does NOT permit new violations.

## Exception Logging (catch convention)

> Triggers `catch / ExceptionLogHelper / SalesWeatherLogger / EILogger / application.log` → skill `zdpos-exception-logging` (rules, examples, anti-patterns).

**Hard rule**: every `catch (\Exception $e)` SHALL call both `ExceptionLogHelper::logCaughtExceptionToApplication()` and a domain logger; never empty / `// ignore`.

## Event Dispatch

> Triggers `Yii::app()->eventDispatcher / EventDispatcher / VoucherUsedEvent / AbstractEvent / ListenerInterface / ShouldQueue / dispatchIf / dispatchUnless / until / flush / FakeEventDispatcher` → cookbook `docs/guides/event-dispatcher-cookbook.md` (3 種 listener 形式、Subscriber、Laravel API 對齊、ShouldQueue marker、同步限制、helper API、設計模式 cross-link)。
>
> Triggers `event-dispatcher-design-patterns / 集中注入 Bootstrap / 對稱安全護欄 / per-class reflection cache / snapshot restore trait` → reference `docs/guides/event-dispatcher-design-patterns.md` (6 個可重用設計模式，供日後 form-request / queue-job 等基礎元件重構參考)。

**Hard rules**:
- Dispatcher 入口 SSOT：`Yii::app()->eventDispatcher`（由 `Infrastructure\Events\EventDispatcherBootstrap::register()` 透過 `setPathOfAlias.php`（22 個 merchant config 共用進入點）+ `protected/tests/bootstrap.php` 集中注入）。**禁止** 自己 `new EventDispatcher()`（除單元測試）或在 Controller / Service 內 instantiate dispatcher。
- Listener 註冊 SSOT：`EventDispatcherBootstrap::registerListeners()`。**禁止** 在 Controller `init()` / Service constructor 內呼叫 `listen()` / `subscribe()`。
- Event 物件：繼承 `Infrastructure\Events\AbstractEvent`、放 `domain/{Module}/Events/`，payload 用 public properties。
- Listener 類別：實作 `Infrastructure\Events\ListenerInterface`、放 `domain/{Module}/Listeners/`，`handle($event)` 內若觸發異常需呼叫 `ExceptionLogHelper::logCaughtExceptionToApplication()` 視性質 catch（fire-and-forget audit）或 propagate（critical path）。
- 不寫 wildcard listener（`order.*`），dispatcher 第一階段不支援。
- 重 I/O（外部 API、批次 DB、寄信）**禁止** 同步 listener；等 `add-queue-job-abstract` 與 `ShouldQueue` marker 接好後改 async。同步 listener 內若實作 `ShouldQueue`，dispatcher 會 throw `\LogicException`。

新增 listener / subscriber checklist：(1) Event 物件繼承 AbstractEvent (2) Listener 實作 ListenerInterface (3) 在 `EventDispatcherBootstrap::registerListeners()` 註冊 (4) 寫 integration test 驗證端到端。

## FormRequest / Validation

> Triggers `AbstractFormRequest / validateOrFail / validated() / passes() / fails() / Infrastructure\Validation\Validator / ValidationException / AuthorizationException / rules() / messages() / requiredPermission / prepareForValidation` → cookbook `docs/guides/form-request-cookbook.md`（15 個 rule keyword、Laravel API 對齊表、Yii ACL 整合、`validate` → `validateOrFail` 命名偏離理由、InvoiceListRequest migration 範例）。

**Hard rules**:
- 新 DTO 一律 `extends \Infrastructure\Foundation\Structures\AbstractFormRequest`；既有 `extends AbstractRequest` 子類不強制 migrate（行為已向後相容，自 Bundle E 起 constructor 自動跑 rules）。
- Controller 端驗證入口（Bundle E 起兩種模式並存）：
  - **Drop-in 模式（HTML form / view）**：constructor 已自動跑 rules，`if (!$request->isValid())` 即可顯示錯誤；不需要呼叫 `validateOrFail()`。**禁止** 在 controller 端複製規則檢查（`if (empty($_POST['x']))`）。
  - **Throwing 模式（JSON / AJAX）**：需要 422 / 403 語意時呼叫 `$request->validateOrFail()` 或 `$request->validated()`。**禁止** 新寫散落的 `if (empty($_POST['x']))` / 在 controller 內直接拋 `\InvalidArgumentException`。
- Validation 規則 SSOT：`public function rules()` 內宣告；**禁止** 在 controller 端 inline 重複規則。
- ValidationException catch 端用 `$e->getErrors()` 取 `[field => string[]]` 結構（對齊 Laravel `errors()->all()`）。
- 命名偏離 Laravel：用 `validateOrFail()`（不是 Laravel 的 `validate()`），因既有 `protected function validate()` 與 20 個子類 override 在 PHP 5.6 下無法被 widen — 詳見 `openspec/specs/form-request-abstract/spec.md`。
- **禁止** 引入 Symfony Validator / Respect Validation / illuminate/validation（皆需 PHP 7+）。Validator engine 為自製 `Infrastructure\Validation\Validator`。
- Authorize 走 Yii ACL：子類覆寫 `requiredPermission()` 回 ACL operation 字串；複雜邏輯 override `authorize()`。**禁止** 在 controller 端複製一次同樣的 `Yii::app()->user->checkAccess()` 檢查。Constructor **不自動** 跑 authorize（避免改變既有 `new XxxRequest()` 不 throw 的契約）；ACL 須顯式呼叫 `validateOrFail()` / `passes()` 觸發。

新增 FormRequest 子類 checklist：(1) `extends AbstractFormRequest`（命名空間 `Infrastructure\Foundation\Structures`）(2) `rules()` 宣告至少一條規則 (3) 需要授權時 override `requiredPermission()` (4) 必要時 override `messages()` 提供中文錯誤 (5) controller 端若需 throw 403/422 語意才加 `validateOrFail()` 觸發點，純 HTML form 用 `isValid()` 即可 (6) 寫 integration test（涉及 Yii::app）或 unit test（純 DTO）驗證 rules 行為。

## IN / NOT IN Queries

> Triggers `addInCondition / addNotInCondition / IN clause / array_values` → skill `zdpos-in-queries` (compound LIKE+IN, empty-array guard, anti-patterns).

**Hard rule**: use `CDbCriteria::addInCondition()` / `addNotInCondition()`; never string interpolation; always `array_values($ids)`; guard empty arrays before `addNotInCondition`.

## Validator / DI / Controller Response

- Validator: `class XxxValidator extends CValidator`; rules: `['field', 'ext.validators.XxxValidator']`
- DI: `Yii::app()->getComponent('orderService')`; config `'components' => ['orderService' => ['class' => 'app.services.OrderService']]`
- AJAX uses the `Response` trait. Legacy `['err' => 0/1]` is deprecated.

| Status | Method |
|---|---|
| 200 | `$this->json(['success' => true, 'data' => $r, 'message' => ''])` |
| 400 | `$this->error('reason')` |
| 403 / 404 | `throw new CHttpException(403\|404)` |

## Raw SQL vs Query Builder

| Case | Approach |
|---|---|
| DML, fixed table | Always query builder |
| DDL (SHOW/TRUNCATE/DESCRIBE) or DML with dynamic table | Raw SQL + `$this->assertValidTableName($name)` |

`assertValidTableName()` SSOT lives in `EntityRepository` (`protected`). Legacy `private` copies in `SystemRepository` / `CiwebRepository` are debt — when a new Repo needs it, declare `protected` (pending unification).

## Repository Class Constants

Detail → `php/coding-style.md` "Magic Values". Single-value enums need no `AbstractEnum` subclass.

## PHP 5.6 substitutions (quick ref)

- Named args → `$options` array + `array_merge($defaults, $options)`
- Chainable: `CDbCommand` native; `CDbCriteria` needs wrapping
- Full constraint list → `php/coding-style.md` "PHP 5.6 polyfills"
