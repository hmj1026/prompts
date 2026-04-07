# Security Guidelines

## Mandatory Security Checks

Before ANY commit:
- [ ] Rate limiting on all public endpoints
- [ ] Authentication/authorization verified on protected routes

## Secret Management

- Validate that required secrets are present at startup
- Rotate any secrets that may have been exposed

## Security Response Protocol

If security issue found:
1. STOP immediately
2. Use **security-reviewer** agent
3. Fix CRITICAL issues before continuing
4. Rotate any exposed secrets
5. Review entire codebase for similar issues
