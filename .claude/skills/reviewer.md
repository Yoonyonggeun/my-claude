# Reviewer Skill

## Purpose

Perform comprehensive code review covering **security**, **correctness**, **performance**, **readability**, **testing**, and **token economy** compliance before commits or on-demand.

**Scope:**
- Pre-commit quality gate
- On-demand code audit
- Pull request review automation
- Security vulnerability detection (OWASP Top 10 focus)
- Token consumption analysis

**Out of Scope:**
- Architecture redesign (use repo-recon.md)
- Test generation (use testing-harness.md)
- Requirements validation (use requirements-compiler.md)

## Triggers

**Load this skill when:**
- User explicitly requests code review ("review this", "audit the code", "check for issues")
- User asks to run pre-commit checks
- User requests security scan or vulnerability assessment
- Pull request review needed
- Before marking complex task as complete (self-initiated quality gate)

**Anti-triggers (DO NOT load):**
- Simple typo fixes or single-line changes
- User asks to write/modify code (review comes after, not during)
- Exploratory codebase reading without changes
- Documentation-only updates

## Review Checklist

### 1. SECURITY (Severity: CRITICAL)

**OWASP Top 10 & Common Vulnerabilities:**
- [ ] **Injection Flaws:** SQL, NoSQL, command, LDAP, XPath injection vectors?
- [ ] **XSS:** Unescaped user input in HTML/JS contexts?
- [ ] **Broken Authentication:** Weak password storage, session management, token handling?
- [ ] **Sensitive Data Exposure:** Secrets in code, logs, commits, error messages?
- [ ] **XXE:** XML parsing with external entity processing enabled?
- [ ] **Broken Access Control:** Missing authorization checks, IDOR vulnerabilities?
- [ ] **Security Misconfiguration:** Debug mode in prod, default credentials, verbose errors?
- [ ] **Insecure Deserialization:** Untrusted data deserialized without validation?
- [ ] **Using Components with Known Vulnerabilities:** Outdated dependencies?
- [ ] **Insufficient Logging:** Security events not logged or monitored?

**Additional Security Checks:**
- [ ] **Path Traversal:** User-controlled file paths properly sanitized?
- [ ] **SSRF:** User-controlled URLs validated against internal network access?
- [ ] **CSRF:** State-changing operations protected with tokens?
- [ ] **Rate Limiting:** API endpoints protected against abuse?
- [ ] **File Upload:** File type, size, content validation present?

**Severity Levels:**
- **CRITICAL:** Allows remote code execution, data breach, auth bypass
- **HIGH:** Allows privilege escalation, data manipulation, DoS
- **MEDIUM:** Information disclosure, client-side attacks
- **LOW:** Security hardening opportunities

### 2. CORRECTNESS (Severity: HIGH)

- [ ] **Logic Errors:** Off-by-one, incorrect conditionals, wrong operators?
- [ ] **Edge Cases:** Null/undefined, empty arrays, boundary values handled?
- [ ] **Error Handling:** Try-catch blocks appropriate, errors propagated correctly?
- [ ] **Type Safety:** Type annotations correct (TS), type coercion issues (JS)?
- [ ] **Async Issues:** Race conditions, unhandled promise rejections, callback hell?
- [ ] **Data Validation:** Input validated before processing?
- [ ] **Breaking Changes:** Existing functionality preserved unless intentional?

### 3. PERFORMANCE (Severity: MEDIUM)

- [ ] **Algorithmic Complexity:** O(n²) or worse on large datasets?
- [ ] **N+1 Queries:** Database queries in loops?
- [ ] **Memory Leaks:** Event listeners cleaned up, large objects released?
- [ ] **Unnecessary Work:** Redundant computations, duplicate network calls?
- [ ] **Resource Management:** Files, connections, streams properly closed?
- [ ] **Blocking Operations:** Synchronous I/O on critical paths?

### 4. READABILITY (Severity: LOW)

- [ ] **Naming:** Variables, functions, classes descriptive and consistent?
- [ ] **Function Length:** Functions ≤ 50 lines (or justify exception)?
- [ ] **Code Duplication:** DRY violations (>3 similar blocks)?
- [ ] **Comments:** Complex logic explained, no commented-out code?
- [ ] **Style Consistency:** Matches existing codebase patterns?
- [ ] **Magic Numbers:** Hardcoded values extracted to named constants?

### 5. TESTING (Severity: HIGH)

- [ ] **Test Coverage:** Critical paths covered by tests?
- [ ] **Test Quality:** Tests validate behavior, not implementation?
- [ ] **Edge Case Tests:** Boundary values, error conditions tested?
- [ ] **Test Isolation:** Tests don't depend on execution order?
- [ ] **Mocking:** External dependencies properly mocked?
- [ ] **Test Data:** No production data or secrets in tests?

### 6. TOKEN ECONOMY (Severity: MEDIUM)

- [ ] **Tool Usage:** Task tool used for exploration vs inline Grep loops?
- [ ] **File Reads:** Minimum necessary reads, no redundant reads?
- [ ] **Parallel Calls:** Independent operations executed in parallel?
- [ ] **Skill Loading:** Only necessary skills loaded for task?
- [ ] **Documentation Size:** Always-on docs ≤ 200 lines?

## Output Template

### Findings Report

```markdown
# Code Review Report

**Review Date:** YYYY-MM-DD
**Files Reviewed:** `path/to/file1.ts:10-50`, `path/to/file2.js:30-80`
**Reviewer:** Claude Sonnet 4.5

## Summary

**Status:** ✅ APPROVED | ⚠️ APPROVED WITH COMMENTS | ❌ CHANGES REQUIRED
**Critical Issues:** X
**High Severity:** Y
**Medium Severity:** Z
**Low Severity:** W

---

## Findings

### 1. [CRITICAL] SQL Injection in User Login

**Location:** `src/auth/login.ts:45-47`
**Category:** Security - Injection

**Issue:**
```typescript
const query = `SELECT * FROM users WHERE email = '${email}'`;
db.execute(query);
```

**Risk:** Allows arbitrary SQL execution via crafted email parameter.

**Fix:**
```typescript
const query = 'SELECT * FROM users WHERE email = ?';
db.execute(query, [email]);
```

**Regression Test:**
```typescript
test('login rejects SQL injection attempt', async () => {
  const maliciousEmail = "' OR '1'='1";
  await expect(login(maliciousEmail, 'pass')).rejects.toThrow();
});
```

---

### 2. [HIGH] Missing Error Handling in API Call

**Location:** `src/api/fetch-user.ts:20-25`
**Category:** Correctness

**Issue:**
```typescript
async function fetchUser(id: string) {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}
```

**Risk:** Network failures cause unhandled promise rejections.

**Fix:**
```typescript
async function fetchUser(id: string) {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return response.json();
  } catch (error) {
    logger.error('fetchUser failed', { id, error });
    throw error;
  }
}
```

**Regression Test:**
```typescript
test('fetchUser handles network errors', async () => {
  mockFetch.mockRejectedValueOnce(new Error('Network error'));
  await expect(fetchUser('123')).rejects.toThrow('Network error');
});
```

---

### 3. [MEDIUM] Inefficient N+1 Query

**Location:** `src/services/order-processor.ts:30-35`
**Category:** Performance

**Issue:**
```typescript
for (const order of orders) {
  const user = await db.getUser(order.userId);
  // process order
}
```

**Risk:** O(n) database queries for n orders.

**Fix:**
```typescript
const userIds = orders.map(o => o.userId);
const users = await db.getUsers(userIds);
const userMap = new Map(users.map(u => [u.id, u]));

for (const order of orders) {
  const user = userMap.get(order.userId);
  // process order
}
```

**Regression Test:**
```typescript
test('processOrders executes single bulk query', async () => {
  const orders = [{ userId: '1' }, { userId: '2' }, { userId: '3' }];
  await processOrders(orders);
  expect(db.getUsers).toHaveBeenCalledTimes(1);
  expect(db.getUser).not.toHaveBeenCalled();
});
```

---

## Positive Observations

- ✅ Consistent error logging with structured context
- ✅ Comprehensive input validation on API boundaries
- ✅ No secrets or credentials in codebase

## Recommendations

1. **Security:** Add rate limiting to `/api/login` endpoint
2. **Testing:** Increase coverage for edge cases in `order-processor.ts`
3. **Performance:** Consider caching frequently accessed user data

---

**Next Steps:**
- [ ] Fix CRITICAL issues (blocking merge)
- [ ] Address HIGH severity findings (blocking merge)
- [ ] Review MEDIUM/LOW findings (best effort)
- [ ] Run regression tests
- [ ] Re-review after fixes applied

**Approval Criteria:**
- All CRITICAL and HIGH severity issues resolved
- Regression tests pass
- No new vulnerabilities introduced
```

## Workflow

```
1. SCOPE → Identify files/changes to review (git diff, user-specified paths)
2. READ → Load all affected files (parallel Read calls)
3. ANALYZE → Apply checklist systematically per file
4. DOCUMENT → Generate Findings Report using template
5. VERIFY → Run self-check before delivering
```

**Review Modes:**

| Mode            | Trigger                       | Checklist Sections               |
|-----------------|-------------------------------|----------------------------------|
| Full Review     | Pre-commit, PR review         | All 6 sections                   |
| Security Scan   | "security check", "audit"     | Security only (deep dive)        |
| Quick Check     | Simple changes, typo fixes    | Security + Correctness only      |
| Performance     | "optimize", "slow"            | Performance + Correctness        |

**Scope Detection:**
```bash
# Detect files to review
git diff --name-only HEAD  # Uncommitted changes
git diff --name-only main..HEAD  # PR changes
```

## Output Contract

**Deliverable Structure:**
1. **Findings Report** (markdown, using template above)
2. **File References** (path:line format for all issues)
3. **Severity Triage** (CRITICAL/HIGH block merge, MEDIUM/LOW advisory)
4. **Actionable Fixes** (code snippets, not descriptions)
5. **Regression Tests** (runnable test cases for each finding)

**Format Requirements:**
- Use severity tags: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`
- Include line numbers for all findings
- Provide before/after code blocks
- Link findings to OWASP category where applicable
- No superlatives or praise (objective technical assessment)

## Definition of Done

**Review Complete When:**
- [ ] All files in scope analyzed against checklist
- [ ] Every finding includes: location, issue, risk, fix, test
- [ ] Severity levels assigned based on impact
- [ ] Positive observations noted (if any)
- [ ] Next steps checklist provided
- [ ] Self-check passed (below)

**NOT Done If:**
- Files not read before review
- Findings lack code examples or line references
- Suggested fixes untested or create new vulnerabilities
- Security findings missing OWASP classification

## Self-check

**Run before delivering review:**

```
1. COMPLETENESS
   [ ] All files in scope reviewed?
   [ ] Checklist sections relevant to change type applied?
   [ ] Both code and tests reviewed (if tests modified)?

2. ACCURACY
   [ ] Read actual file contents (not assumptions)?
   [ ] Line numbers verified correct?
   [ ] Suggested fixes tested for correctness?
   [ ] No false positives (findings are real issues)?

3. SEVERITY CALIBRATION
   [ ] CRITICAL: Actually allows RCE/data breach/auth bypass?
   [ ] HIGH: Actually breaks functionality or allows escalation?
   [ ] MEDIUM: Actually degrades performance/security posture?
   [ ] LOW: Actually impacts readability/maintainability?

4. ACTIONABILITY
   [ ] Every finding includes concrete fix code?
   [ ] Regression tests provided and runnable?
   [ ] User can implement fixes without additional research?

5. TOKEN ECONOMY
   [ ] Used parallel Read calls for multiple files?
   [ ] Avoided redundant file reads?
   [ ] Findings concise, no verbose explanations?
```

## Examples

### Example 1: Security Scan

**Input:** User requests "security check on auth module"

**Execution:**
```
1. Scope: src/auth/**/*.ts
2. Load files in parallel
3. Deep dive Security checklist section only
4. Generate findings report with OWASP tags
5. Provide exploit scenarios + fixes + tests
```

### Example 2: Pre-commit Full Review

**Input:** User runs `/commit` (reviewer.md auto-triggered)

**Execution:**
```
1. Scope: git diff --cached --name-only
2. Load staged files
3. Apply all 6 checklist sections
4. Block commit if CRITICAL/HIGH findings exist
5. Generate report with approval status
```

### Example 3: Performance Review

**Input:** User says "review performance of order-processor.ts"

**Execution:**
```
1. Scope: src/services/order-processor.ts
2. Load file + related tests
3. Focus Performance + Correctness sections
4. Identify bottlenecks (N+1, O(n²), memory leaks)
5. Provide optimized code + benchmarks
```

## Meta

- **Skill Version:** 1.0.0
- **Load Strategy:** On-demand only (never always-on)
- **Dependencies:** None (standalone skill)
- **Token Budget:** ~50-200 tokens per file reviewed
- **Unload After:** Findings report delivered

---
**End of reviewer.md** • Code quality gate for safe, performant, secure delivery
