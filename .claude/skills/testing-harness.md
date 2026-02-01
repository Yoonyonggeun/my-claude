# Testing Harness Skill

## Purpose

Provide a **minimal, project-aware verification strategy** for code changes. This skill standardizes how to validate implementations through testing, linting, type-checking, and regression verification without over-engineering.

**Core Principle:** Run only what's necessary to catch regressions and verify the specific change—no more, no less.

---

## Load Triggers

**Load this skill when:**
- Code implementation just completed (new feature, bug fix, refactor)
- User explicitly requests "run tests", "verify this", "check if it works"
- Pull request creation flow requires verification plan
- DoD checklist requires test execution
- Post-implementation phase in EXPLORE → PLAN → IMPLEMENT → **VERIFY** workflow

**Anti-triggers (do NOT load):**
- Exploring codebase without code changes (use Explore agent instead)
- Planning phase (no code written yet)
- User only wants test strategy explanation (answer inline)
- Documentation-only changes with no executable code

---

## Workflow

```
1. DISCOVER  → Identify available verification tools in project
2. SELECT    → Choose minimal sufficient test strategy
3. EXECUTE   → Run verification commands
4. INTERPRET → Analyze results against acceptance criteria
5. REPORT    → Deliver pass/fail status with evidence
```

---

## Discovery Protocol

**Objective:** Determine what verification infrastructure exists WITHOUT assuming.

### Step 1: Identify Test Framework

**Check for (in order of priority):**

```bash
# Package manifest
[ -f package.json ] && grep -E '"(test|jest|vitest|mocha|playwright|cypress)"' package.json

# Config files (parallel check)
ls {jest,vitest,playwright,cypress,mocha}.config.{js,ts,mjs,cjs,json} 2>/dev/null

# Build tools
ls {vite,webpack,rollup,tsup}.config.{js,ts,mjs} 2>/dev/null

# Python
[ -f pyproject.toml ] && grep -E '\[(tool\.pytest|tool\.coverage)\]' pyproject.toml
[ -f setup.py ] && grep -E 'pytest|unittest|nose' setup.py

# Go
[ -f go.mod ] && ls *_test.go 2>/dev/null

# Rust
[ -f Cargo.toml ] && ls tests/ 2>/dev/null
```

**Output:** List of detected frameworks (e.g., "Jest, Playwright, Go native tests")

### Step 2: Identify Linter/Formatter

```bash
# JavaScript/TypeScript
ls .eslintrc* eslint.config.* 2>/dev/null
ls .prettierrc* prettier.config.* 2>/dev/null
grep -E '"lint":|"format":' package.json

# Python
ls .ruff.toml ruff.toml .flake8 pyproject.toml 2>/dev/null
grep -E 'black|ruff|flake8|pylint' pyproject.toml

# Go
command -v golangci-lint && echo "golangci-lint available"

# Rust
grep '\[lints\]' Cargo.toml
```

**Output:** Linter commands (e.g., "npm run lint", "ruff check .", "cargo clippy")

### Step 3: Identify Type Checker

```bash
# TypeScript
ls tsconfig.json && echo "tsc available"

# Python
grep 'mypy' pyproject.toml || command -v mypy

# Go
echo "go vet (built-in)"
```

**Output:** Type check command (e.g., "tsc --noEmit", "mypy .", "go vet ./...")

### Step 4: Check CI Configuration (Optional Context)

```bash
ls .github/workflows/*.{yml,yaml} 2>/dev/null | head -3
ls .gitlab-ci.yml .circleci/config.yml 2>/dev/null
```

**Purpose:** Understand production verification expectations (informational only—don't replicate full CI locally).

---

## Minimal Verification Checklist

**For ANY code change, verify:**

### ✅ Core Verification (MANDATORY)

| Check | Command Pattern | Failure Action |
|-------|----------------|----------------|
| **Syntax Valid** | Language-specific parse (tsc/python -m py_compile/go build) | BLOCK—fix before proceeding |
| **Existing Tests Pass** | Run test suite scoped to changed area | BLOCK—regression detected |
| **No Lint Violations** | Run linter on changed files only | WARN—fix if related to change |

### 🔄 Extended Verification (When Applicable)

| Condition | Check | Command Example |
|-----------|-------|-----------------|
| TypeScript/typed language | Type safety | `tsc --noEmit` or `mypy changed_file.py` |
| New function added | Unit test exists | Check test file for new test case |
| API/integration change | Integration test passes | `npm test -- integration` or `pytest tests/integration` |
| UI component modified | Visual/E2E test | `playwright test affected.spec.ts` (if Playwright exists) |

### ⚠️ Unknown Commands Handling

**If verification command is unclear:**

1. **Check package.json scripts** (or equivalent):
   ```bash
   jq '.scripts' package.json
   ```
2. **Search for README/CONTRIBUTING.md**:
   ```bash
   grep -i "test\|lint\|ci" README.md CONTRIBUTING.md
   ```
3. **Fallback to generic commands**:
   - **Node.js:** `npm test`, `npm run lint`, `npm run type-check`
   - **Python:** `pytest`, `ruff check .`, `mypy .`
   - **Go:** `go test ./...`, `go vet ./...`
4. **If still unknown:** Ask user: "How do you normally run tests in this project?"

---

## Execution Strategy

### Scope Optimization (Token Economy)

**Principle:** Run the **minimum test surface** that validates the change.

| Change Type | Recommended Scope | Example Command |
|-------------|------------------|-----------------|
| Single file edit | Tests for that file only | `jest src/utils/auth.test.ts` |
| Module refactor | Tests for that module | `pytest tests/auth/` |
| Cross-cutting change | Full test suite | `npm test` |
| Dependency update | Smoke tests + critical paths | `npm test -- --testPathPattern=critical` |

**Avoid:**
- Running full E2E suite for typo fixes
- Re-running unaffected test files
- Executing tests for unchanged modules

### Parallel Execution

**When possible, run verification steps in parallel:**

```bash
# Example: Run lint + type-check + tests concurrently
npm run lint & npm run type-check & npm test -- --changed
wait  # Collect all results
```

**Use only if:**
- Commands are independent (no shared state)
- System resources sufficient (don't overload in CI)

---

## Output Template

### Verification Plan

**Before executing, output:**

```markdown
## Verification Plan

**Changed Files:**
- `src/auth/login.ts` (modified authentication logic)
- `src/auth/login.test.ts` (updated tests)

**Verification Strategy:**
1. **Type Check:** `tsc --noEmit` (entire codebase—ensures no type regressions)
2. **Lint:** `eslint src/auth/login.ts` (scoped to changed file)
3. **Unit Tests:** `jest src/auth/login.test.ts` (specific test file)
4. **Integration Test:** `npm test -- --testPathPattern=auth` (auth module only)

**Expected Results:**
- Type check: 0 errors
- Lint: 0 warnings (or existing warnings unchanged)
- Unit tests: 4/4 passed
- Integration tests: 2/2 passed

**Execution Time Estimate:** ~30s (type-check: 10s, lint: 5s, tests: 15s)

---
**Proceeding with execution...**
```

### Execution Report

**After running commands, output:**

```markdown
## Verification Results

### ✅ Type Check
Command: `tsc --noEmit`
Status: PASSED
Output: (suppressed—no errors)

### ✅ Lint
Command: `eslint src/auth/login.ts`
Status: PASSED
Output: (suppressed—no warnings)

### ✅ Unit Tests
Command: `jest src/auth/login.test.ts`
Status: PASSED
```
PASS  src/auth/login.test.ts
  ✓ authenticates valid user (23ms)
  ✓ rejects invalid credentials (18ms)
  ✓ handles expired tokens (15ms)
  ✓ rate limits login attempts (31ms)

Tests: 4 passed, 4 total
```

### ❌ Integration Tests
Command: `npm test -- --testPathPattern=auth`
Status: FAILED
```
FAIL  tests/integration/auth.test.ts
  ✓ full login flow (145ms)
  ✕ password reset flow (89ms)

  ● password reset flow
    Expected status 200, received 500
    at tests/integration/auth.test.ts:42:18

Tests: 1 failed, 1 passed, 2 total
```

---

## Summary
**Overall Status:** ❌ FAILED (1 integration test failing)

**Blocking Issues:**
- Password reset endpoint returning 500 error (tests/integration/auth.test.ts:42)

**Recommendation:** Fix password reset logic in `src/auth/reset.ts` before proceeding.
```

---

## Regression Detection

**If existing tests fail after change:**

1. **Isolate Failure:**
   - Run single failing test: `npm test -- path/to/test.ts -t "specific test name"`
   - Check if failure is deterministic (run 3 times)

2. **Root Cause Analysis:**
   - Compare test expectations vs actual output
   - Check if change intentionally altered behavior (expected breaking change)
   - Review recent commits: `git log -3 --oneline -- path/to/changed/file.ts`

3. **Decision Matrix:**

| Scenario | Action |
|----------|--------|
| Test expectation outdated | Update test to match new correct behavior |
| Unintended regression | Revert change, fix implementation |
| Flaky test (race condition) | Stabilize test or mark as skipped with TODO |
| Dependency issue | Check for version conflicts, update lockfile |

4. **NEVER:**
   - Blindly update snapshots without reviewing changes
   - Comment out failing tests to "make it pass"
   - Merge with known failures unless explicitly approved by user

---

## Output Contract

**Deliverables:**

1. **Verification Plan** (pre-execution):
   - Changed files list
   - Commands to run with scope justification
   - Expected pass criteria

2. **Execution Report** (post-execution):
   - Command + status for each check
   - Full output for failures, summary for passes
   - Overall PASS/FAIL status

3. **Actionable Recommendations** (if failures):
   - Specific file:line references for errors
   - Root cause hypothesis
   - Suggested fix OR request for user guidance

**Format Requirements:**
- Use emoji status indicators (✅❌⚠️)
- Include actual command run (copy-pasteable)
- Show test counts (X passed, Y failed, Z total)
- Provide file:line references for failures

---

## Definition of Done

**Verification task complete when:**

- [ ] Discovery phase identified all available verification tools
- [ ] Minimal verification plan executed (no unnecessary full suite runs)
- [ ] All results reported with PASS/FAIL status
- [ ] Failures include file:line references and root cause analysis
- [ ] User can reproduce results using provided commands
- [ ] No false negatives (tests passing when they should fail)
- [ ] Self-check completed (see below)

**NOT done if:**
- Tests skipped without justification
- Failures present but not analyzed
- Commands failed due to environment issues (missing dependencies) without resolution
- User cannot verify results independently

---

## Self-check

**Before reporting completion:**

```
[ ] DISCOVERY
    [ ] Checked for test framework config files?
    [ ] Identified linter/formatter tools?
    [ ] Located type checker (if typed language)?
    [ ] Verified commands actually exist in project?

[ ] SCOPE
    [ ] Ran minimum necessary tests (not entire suite for small change)?
    [ ] Justified any full suite runs?
    [ ] Avoided redundant verification steps?

[ ] EXECUTION
    [ ] All commands actually executed (not simulated)?
    [ ] Captured real output (not placeholder text)?
    [ ] Handled command failures gracefully?
    [ ] Parallel execution used where applicable?

[ ] REPORTING
    [ ] PASS/FAIL status clear for each check?
    [ ] Failure output includes file:line references?
    [ ] Commands copy-pasteable for user reproduction?
    [ ] Regression analysis completed for failures?

[ ] TOKEN ECONOMY
    [ ] No redundant test runs?
    [ ] Avoided loading full test output for passes?
    [ ] Used scoped commands vs full suite where possible?
```

---

## Edge Cases

### No Test Framework Found

**Response:**
```markdown
⚠️ **No test framework detected in project.**

**Discovery Results:**
- No package.json test scripts found
- No test config files (jest/vitest/playwright/etc.)
- No test files matching *{.test,.spec}.{js,ts,py} pattern

**Recommendation:**
1. Manual verification: Run application and test changed functionality
2. Suggest adding test framework: [provide 1-2 options based on project type]
3. Ask user: "How do you currently verify changes in this project?"
```

### All Verification Tools Missing (Legacy/Minimal Project)

**Fallback Strategy:**
1. **Syntax check only:** Attempt to compile/parse changed files
2. **Manual test plan:** Provide user with step-by-step manual verification checklist
3. **Recommend tooling:** Suggest minimal setup (e.g., "Consider adding `npm test` script")

### Tests Pass Locally but User Reports CI Failure

**Response:**
```markdown
⚠️ **Local verification passed but CI may have additional checks.**

**Possible Causes:**
- Environment differences (Node version, OS, dependencies)
- CI runs additional checks (e.g., security scan, license check)
- Stricter linting rules in CI
- Integration tests with external services

**Recommendations:**
1. Check CI logs for specific failure
2. Run CI commands locally if reproducible
3. Verify environment parity (Node version, package lockfile committed)
```

---

## Examples

### Example 1: Simple Bug Fix in TypeScript Project

**Context:** Fixed off-by-one error in `src/utils/pagination.ts`

**Verification Plan:**
```markdown
## Verification Plan
**Changed Files:** src/utils/pagination.ts

**Strategy:**
1. Type check: `tsc --noEmit` (ensure no type errors)
2. Unit tests: `jest src/utils/pagination.test.ts` (specific test file)
3. Lint: `eslint src/utils/pagination.ts` (scoped)

**Expected:** All checks pass, 6/6 unit tests green.
```

**Execution:**
```bash
tsc --noEmit && jest src/utils/pagination.test.ts && eslint src/utils/pagination.ts
```

**Result:** ✅ All passed → Mark task complete.

---

### Example 2: New Feature with Integration Tests

**Context:** Added OAuth login flow (4 files changed)

**Verification Plan:**
```markdown
## Verification Plan
**Changed Files:**
- src/auth/oauth.ts (new)
- src/auth/oauth.test.ts (new)
- src/routes/auth.ts (modified)
- tests/integration/login.spec.ts (modified)

**Strategy:**
1. Type check: `tsc --noEmit` (full codebase)
2. Unit tests: `jest src/auth/oauth.test.ts` (new tests)
3. Integration tests: `playwright test tests/integration/login.spec.ts` (affected E2E)
4. Lint: `eslint src/auth/ src/routes/auth.ts` (changed areas)

**Expected:**
- Type: 0 errors
- Unit: 8/8 passed
- Integration: 3/3 passed (new OAuth flow scenario)
```

**Execution:** Run in parallel where possible.

---

### Example 3: Dependency Update

**Context:** Updated `react` from 18.2.0 → 18.3.0

**Verification Plan:**
```markdown
## Verification Plan
**Changed Files:** package.json, package-lock.json

**Strategy:**
1. Smoke tests: `npm test -- --testPathPattern=smoke` (critical paths only)
2. Type check: `tsc --noEmit` (ensure no type breakage from React update)
3. Build check: `npm run build` (verify production build succeeds)

**Rationale:** Not running full suite (500+ tests) for patch update; smoke tests catch major breakages.

**Expected:** Smoke tests (12) + build pass.
```

**Result:** If smoke tests pass → ✅ Done. If fail → Run full suite to isolate issue.

---

## Anti-patterns

**AVOID:**

❌ **Over-testing:**
```markdown
Running full E2E suite (200 tests, 15min) for README typo fix
```

❌ **Under-testing:**
```markdown
"Looks good visually, skipping tests" for database migration
```

❌ **Snapshot Blindness:**
```markdown
`npm test -- -u` without reviewing changed snapshots
```

❌ **Ignoring Failures:**
```markdown
"Test failed but it's probably flaky, merging anyway"
```

❌ **Environment Assumptions:**
```markdown
"Works on my machine" without checking CI config differences
```

---

## Meta

- **Skill Type:** On-demand (load when verification needed)
- **Token Budget:** ≤ 300 lines (current: ~470—will optimize if needed)
- **Dependencies:** Bash tool, project-specific test frameworks
- **Version:** 1.0.0
- **Last Updated:** 2026-02-01

---

**End of testing-harness.md** • Minimal, project-aware verification protocol
