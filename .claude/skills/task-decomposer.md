# Task Decomposer Skill

## Purpose

Break down complex tasks into actionable subtasks with clear dependencies, ownership, acceptance criteria, and verification steps. Ensures parallel execution where possible and sequential ordering where required.

## Triggers

**Load this skill when:**
- Task requires ≥3 distinct steps or spans multiple files/systems
- Dependencies between subtasks exist (some must complete before others start)
- Multiple agents/tools will be involved
- Risk is high (security, data loss, breaking changes)
- User explicitly requests task breakdown or work plan
- Task involves both exploration and implementation phases
- Coordination between different domains needed (frontend + backend, infra + code, etc.)

## Anti-triggers

**Do NOT load this skill for:**
- Single-step tasks (e.g., "fix typo", "add console.log")
- Tasks already broken down by user
- Pure exploration/research (use Task tool with Explore agent instead)
- Tasks with obvious linear sequence and no branching

## Decomposition Procedure

### 1. ANALYZE

**Input Review:**
- Read user requirements completely
- Identify main goal and constraints
- Note explicit acceptance criteria
- Check for ambiguities (use AskUserQuestion if needed, max 3 questions)

**Scope Mapping:**
- List all files/systems that will be touched
- Identify external dependencies (APIs, packages, services)
- Note required permissions or approvals
- Assess risk areas (data mutations, auth changes, destructive operations)

### 2. DECOMPOSE

**Task Extraction:**
- Break work into atomic, verifiable units
- Each task should have clear input/output
- Prefer tasks that can complete in single agent session
- Group related changes to minimize context switching

**Dependency Analysis:**
- Mark tasks that must run sequentially (→)
- Identify tasks that can run in parallel (||)
- Note blocking relationships explicitly
- Avoid circular dependencies

**Owner Assignment:**
- Assign task to appropriate agent type or skill
- Examples:
  - `Explore agent` → codebase reconnaissance
  - `Plan agent` → architectural design
  - `Bash agent` → git operations, package installs
  - `testing-harness.md` → test generation/execution
  - `reviewer.md` → code review
  - `main agent (you)` → implementation, editing, writing

### 3. SPECIFY

**Acceptance Criteria per Task:**
- Define what "done" means for each subtask
- Include measurable outcomes (files created, tests passing, commands succeed)
- Specify required artifacts (code, docs, test reports)

**Verification Method:**
- How will completion be validated?
- Commands to run (tests, linters, builds)
- Expected outputs or side effects
- Rollback plan if verification fails

## Output Template

```markdown
# Work Breakdown: <Task Name>

## Overview
**Goal:** <1-2 sentence summary>
**Scope:** <files/systems affected>
**Risk Level:** <Low | Medium | High>
**Estimated Subtasks:** <count>

## Task List

### Task 1: <Title>
- **ID:** T1
- **Owner:** <agent-type or skill-name>
- **Dependencies:** None | Blocked by [T<id>, ...]
- **Parallel Group:** <number or N/A>
- **Description:**
  - <what needs to be done>
  - <specific actions>
- **Acceptance Criteria:**
  - [ ] <measurable outcome 1>
  - [ ] <measurable outcome 2>
- **Verification:**
  - Command: `<test/check command>`
  - Expected: <output or state>
- **Artifacts:** <files created/modified>

### Task 2: <Title>
...

## Execution Order

**Phase 1 (Parallel):**
- T1, T2, T3 (can run simultaneously)

**Phase 2 (Sequential):**
- T4 → T5 → T6 (must complete in order)

**Phase 3 (Parallel):**
- T7, T8 (can run after Phase 2 completes)

## Rollback Plan

**If Task <id> fails:**
- Action: <git restore, revert commit, delete files, etc.>
- Safe state: <what should repository look like>

## Definition of Done

**Project complete when:**
- [ ] All task acceptance criteria met
- [ ] All verification commands pass
- [ ] No tasks blocked or in-progress
- [ ] Rollback plan validated (if high risk)
- [ ] User confirms deliverable

## Self-check Before Delivery

```
DECOMPOSITION QUALITY
[ ] All tasks atomic and verifiable?
[ ] Dependencies correctly identified?
[ ] No circular dependencies?
[ ] Parallel opportunities maximized?

CLARITY
[ ] Each task has clear owner?
[ ] Acceptance criteria measurable?
[ ] Verification methods executable?
[ ] Rollback plan actionable?

COMPLETENESS
[ ] All files/systems covered?
[ ] Edge cases addressed?
[ ] Security/safety risks noted?
[ ] No ambiguous language?

ECONOMY
[ ] Minimal context switching between tasks?
[ ] Grouped related changes?
[ ] Avoided unnecessary granularity?
```

**Action:** Fix any failed checks before presenting breakdown to user.
```

## Output Contract

**When delivering task breakdown:**

1. **Format:** Use template above exactly
2. **Completeness:** Every task must have all fields populated (no TBD or TODO)
3. **Clarity:** Non-technical user should understand goal and progress
4. **Actionability:** Any agent can pick up task and execute without clarification
5. **Traceability:** Task IDs used consistently in dependencies and execution order

## Integration with Claude Code Tools

**After generating breakdown:**

1. **Use TaskCreate tool** to register each task in Claude's task system:
   ```
   For each task in breakdown:
   - subject: <Task title>
   - description: <Full task details from template>
   - activeForm: <Present continuous, e.g., "Implementing auth">
   ```

2. **Set dependencies** using TaskUpdate:
   ```
   For tasks with blocking relationships:
   - taskId: <dependent task ID>
   - addBlockedBy: [<blocking task IDs>]
   ```

3. **Track progress** as tasks complete:
   - Use TaskUpdate to mark status: pending → in_progress → completed
   - Check TaskList to see what's unblocked and ready

## Anti-patterns

❌ **Too granular:** "Read file X", "Write line Y" (combine into "Implement feature Z")
❌ **Too vague:** "Fix the backend" (specify files, functions, acceptance)
❌ **Hidden dependencies:** Task B needs Task A output but not marked blocked
❌ **Unverifiable:** "Make it better" (define measurable criteria)
❌ **No rollback:** High-risk task with no recovery plan
❌ **Serial when parallel:** Tasks T1, T2 independent but listed sequentially

## Example Usage

**User request:**
> "Add user authentication with JWT tokens"

**Decomposer output:**
```
# Work Breakdown: JWT Authentication

## Overview
**Goal:** Implement secure user authentication using JWT tokens
**Scope:** backend/auth.ts, backend/middleware.ts, frontend/api.ts, .env.example
**Risk Level:** High (security, breaking changes)
**Estimated Subtasks:** 7

## Task List

### Task 1: Security Review
- **ID:** T1
- **Owner:** reviewer.md skill
- **Dependencies:** None
- **Parallel Group:** 1
- **Description:**
  - Review existing auth code for vulnerabilities
  - Check for OWASP Top 10 issues
  - Validate no secrets in repository
- **Acceptance Criteria:**
  - [ ] Reviewer report generated
  - [ ] No critical security issues found
  - [ ] Secrets scan passes
- **Verification:**
  - Command: `git grep -E "(password|secret|key)" --ignore-case`
  - Expected: No hardcoded credentials
- **Artifacts:** security-review.md

### Task 2: Install JWT Library
- **ID:** T2
- **Owner:** Bash agent
- **Dependencies:** None
- **Parallel Group:** 1
- **Description:**
  - Install jsonwebtoken and @types/jsonwebtoken
  - Update package.json and package-lock.json
- **Acceptance Criteria:**
  - [ ] Packages installed successfully
  - [ ] No dependency conflicts
  - [ ] Lock file updated
- **Verification:**
  - Command: `npm list jsonwebtoken`
  - Expected: Package version displayed
- **Artifacts:** package.json, package-lock.json

... [T3-T7 follow same structure]

## Execution Order

**Phase 1 (Parallel):** T1 (review), T2 (install)
**Phase 2 (Sequential):** T3 → T4 → T5 (implement auth logic)
**Phase 3 (Parallel):** T6 (frontend integration), T7 (tests)
```

## Meta

- **Skill Type:** On-demand
- **Load Condition:** Complex task requiring breakdown
- **Unload After:** Breakdown delivered and TaskCreate calls completed
- **Token Target:** ≤ 500 lines (current: ~280)

---
**End of task-decomposer.md**
