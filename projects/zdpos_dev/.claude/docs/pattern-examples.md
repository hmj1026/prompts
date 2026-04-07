# Design Pattern Code Examples (從 common/patterns.md 提取)

> 本檔為 always-on rules 瘦身後的 code example 參考，按需查閱。

## Fluent Interface / Method Chaining

```
query = new QueryBuilder()
  .select("name", "email")
  .where("active", true)
  .orderBy("name")
  .limit(10)
  .build()
```

## Declarative Sequence / Pipeline

```
// WRONG: nested
format(validate(parse(normalize(input))))

// CORRECT: pipeline
result = pipeline(input)
  .then(normalize)
  .then(parse)
  .then(validate)
  .then(format)
```

## Named Arguments / Options Object

```
// WRONG: positional args
createUser("John", true, false, 30, "admin")

// CORRECT: options object
createUser({
  name: "John",
  isActive: true,
  sendEmail: false,
  age: 30,
  role: "admin"
})
```

## Lazy Evaluation Chaining

```
results = repository
  .where("status", "active")   // lazy
  .orderBy("created_at")       // lazy
  .limit(20)                   // lazy
  .toArray()                   // terminal: NOW executes
```
