> This file extends `~/.claude/rules/common/security.md` with PHP specific content.

# PHP Security

## Critical Checklist (Before Any Commit)

- [ ] **SQL Injection**: All queries use PDO prepared statements (`:param` binding)
- [ ] **XSS**: All user output escaped with `CHtml::encode()`
- [ ] **CSRF**: Forms include CSRF token (Yii enabled by default)
- [ ] **Authentication**: Controllers verify `!Yii::app()->user->isGuest`
- [ ] **Authorization**: Resource ownership checked before mutations
- [ ] **Secrets**: NO hardcoded keys (use environment variables)
- [ ] **Input Validation**: All user inputs validated before processing
- [ ] **File Upload**: Extension whitelist, MIME check, store outside webroot
- [ ] **Session Security**: HTTPS enforced, secure/httponly cookies set
- [ ] **Headers**: X-Frame-Options, X-Content-Type-Options set

## Key Rules by Topic

| Topic | Rule |
|-------|------|
| **SQL** | `CDbCommand::bindParam(`:id`, $id, PDO::PARAM_INT)` OR `Order::model()->findByPk()` |
| **Output** | `CHtml::encode($userInput)` — escape everything |
| **Input** | Use Yii model `rules()`: `['email', 'email']`, `['status', 'in', 'range' => [...]]` |
| **Auth** | `if (Yii::app()->user->isGuest) throw CHttpException(403)` |
| **CSRF** | Auto-included in `CActiveForm` via `beginWidget()` |
| **Secrets** | `getenv('API_KEY')` from `.env`, never hardcode |
| **Upload** | Whitelist extensions, check `$_FILES['size']`, store outside webroot |
| **Session** | Cookie params: `httponly => true`, `secure => true` |
| **Headers** | `header('X-Frame-Options: SAMEORIGIN')` in base controller |

## Detailed Examples & Migration Guide

> 完整代碼範例見 `php-pro` skill → `references/php56-legacy.md` 與 `references/testing-quality.md`
