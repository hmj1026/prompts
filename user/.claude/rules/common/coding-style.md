# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```
// Pseudocode
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

Rationale: Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Guard Clauses (Early Return)

Validate preconditions at the top, return/throw early. Keeps the happy path unindented:

```
// WRONG: deeply nested
function process(order) {
  if (order) {
    if (order.isValid) {
      if (order.items.length > 0) {
        // actual logic buried at level 3
      }
    }
  }
}

// CORRECT: guard clauses
function process(order) {
  if (!order) return error("no order")
  if (!order.isValid) return error("invalid")
  if (order.items.length === 0) return error("empty")

  // happy path at level 0
}
```

Rules:
- Check error/edge cases first, exit immediately
- One guard per condition (no compound guards)
- Happy path stays at lowest indentation level

## SLAP (Single Level of Abstraction Principle)

Each function should operate at ONE abstraction level. Mix of high-level orchestration and low-level detail is a code smell:

```
// WRONG: mixed levels
function processOrder(order) {
  // high-level: validate
  validate(order)
  // suddenly low-level: raw SQL, string formatting
  db.query("INSERT INTO orders ...")
  email = "Dear " + order.customer + "..."
  sendEmail(email)
}

// CORRECT: uniform high-level
function processOrder(order) {
  validate(order)
  saveOrder(order)
  notifyCustomer(order)
}
```

Rules:
- If a function mixes orchestration + implementation detail, extract the detail into a helper
- Read the function top-to-bottom: every line should be at the same conceptual level
- Indicator: if you need a blank-line "paragraph break" to separate concerns, extract a function

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)
