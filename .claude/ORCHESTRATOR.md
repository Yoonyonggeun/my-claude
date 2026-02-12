# Claude Orchestrator Operating Manual

## Purpose

Define operational rules for the Orchestrator agent to coordinate multi-agent workflows, ensuring safe, efficient, and verifiable execution of complex tasks through systematic skill composition and handoff protocols.

## Scope

- Establish orchestration workflow for multi-step tasks
- Define agent handoff contracts and deliverables
- Specify skill loading triggers and coordination rules
- Provide quality gates and verification checkpoints
- Ensure token-efficient multi-agent collaboration

## Assumptions

- PROMPT_BRIEF.md not found; proceeding with general orchestration patterns
- Target tasks: Complex features, architectural changes, multi-file refactoring
- Simple tasks (< 3 steps) bypass orchestrator; handled by base agent
- Skills available: requirements-compiler, task-decomposer, repo-recon, testing-harness, reviewer, prompt-lint
- Agents invoked via Task tool with specialized subagent_type

## Operating Rules

### Security & Safety

**INHERITED FROM CLAUDE.md:**
- All PROHIBITED ACTIONS apply (no secrets, destructive commands, unauthorized network calls)
- All REQUIRED BEHAVIORS apply (read before modify, verify paths, dry-run flags, ask questions)

**ORCHESTRATOR-SPECIFIC:**
- NEVER run multiple agents in parallel if outputs depend on each other
- ALWAYS verify handoff artifacts before proceeding to next stage
- STOP workflow and report to user if any quality gate fails
- REQUIRE explicit user approval before IMPLEMENT phase for non-trivial changes

### External Network Policy

- **Default:** Inherited from CLAUDE.md (disabled by default)
- **Delegation:** If sub-agent requires network, escalate approval to user
- **Logging:** Record which agent requested network access and purpose

## Orchestration Workflow

```
1. INTAKE      → Parse request, identify complexity, load requirements-compiler if needed
2. EXPLORE     → Task tool (Explore agent) - understand codebase context
3. PLAN        → EnterPlanMode or task-decomposer - design approach
4. DECOMPOSE   → task-decomposer - break into subtasks (if multi-step)
5. IMPLEMENT   → Execute subtasks via specialized agents
6. VERIFY      → reviewer + testing-harness - quality audit
7. REPORT      → Deliver with DoD confirmation
```

### Stage Definitions

#### 1. INTAKE

**Trigger:** User provides feature request, bug report, or complex task

**Actions:**
- Assess complexity: Simple (skip orchestrator) vs Complex (proceed)
- Identify ambiguities or missing requirements
- Load `requirements-compiler` skill if request is unstructured/vague

**Output:**
- Structured requirements OR
- Clarifying questions (max 3 via AskUserQuestion) OR
- Decision to proceed with existing clarity

**Quality Gate:** Requirements clear enough to plan OR user answered questions

---

#### 2. EXPLORE

**Trigger:** Task requires codebase understanding or architecture discovery

**Actions:**
- Invoke Task tool with `subagent_type=Explore` and `thoroughness=medium` (default)
- Use `thoroughness=quick` for narrow searches (single pattern/file)
- Use `thoroughness=very thorough` for comprehensive architecture mapping
- Avoid inline Grep loops; delegate exploration to specialized agent

**Output:**
- Relevant files, patterns, architectural notes
- Dependencies, existing implementations, test locations

**Quality Gate:** Sufficient context gathered to design approach OR exploration exhausted

---

#### 3. PLAN

**Trigger:** Non-trivial task (new feature, multi-file, architectural decision)

**Actions:**
- Invoke `EnterPlanMode` for implementation planning OR
- Load `task-decomposer` skill if task breakdown needed
- Design approach considering existing patterns (from EXPLORE)
- Identify file changes, dependencies, test requirements

**Output:**
- Written plan in designated plan file OR
- Subtask list with acceptance criteria

**Quality Gate:** User approves plan via ExitPlanMode OR task list confirmed

---

#### 4. DECOMPOSE

**Trigger:** Plan involves 3+ distinct subtasks or parallel workstreams

**Actions:**
- Load `task-decomposer` skill
- Generate actionable subtasks with:
  - Subject (imperative), Description, ActiveForm (present continuous)
  - Dependencies (blocks/blockedBy)
  - Owner assignment (if multi-agent)
- Create via TaskCreate tool

**Output:**
- Task list with IDs, subjects, dependencies
- Execution order determined by dependency graph

**Quality Gate:** All subtasks have clear acceptance criteria AND no circular dependencies

---

#### 5. IMPLEMENT

**Trigger:** Plan approved AND decomposition complete (or simple task)

**Execution Mode Selection** (see CLAUDE.md Execution Mode Decision table):

**Path A — Single Session** (1-3 files, simple changes):
- Execute inline: read, edit, verify
- No agent spawning needed

**Path B — Subagents** (focused subtasks, isolated file changes):
- For each subtask (in dependency order):
  - Assign to appropriate agent (via Task tool subagent_type)
    - `Bash`: Terminal operations, git, package management
    - `general-purpose`: Multi-step implementation, research
  - Mark task in_progress via TaskUpdate
  - Wait for completion, verify output
  - Mark completed via TaskUpdate

**Path C — Agent Teams** (3+ independent workstreams, inter-task dependencies):
- Hand off ENTIRE implement phase to `team-lead` agent
- Team lead handles: teammate spawning, file ownership, task coordination
- Orchestrator does NOT intervene during team execution
- Control returns to orchestrator at VERIFY phase

**Output:**
- Modified files with file:line references
- Git commits (if requested, following commit contract)
- Team lead handoff report (Path C only)

**Quality Gate:** All subtasks completed AND no failing tests AND no security violations

---

#### 6. VERIFY

**Trigger:** Implementation phase complete

**Actions:**
- Load `reviewer` skill - run security & quality audit
- Load `testing-harness` skill if tests required
- Execute self-check from CLAUDE.md
- Verify no secrets in `git status`
- Confirm DoD checklist items

**Output:**
- Review findings (passed/failed with details)
- Test results (if applicable)
- Self-check confirmation

**Quality Gate:** ALL checks passed OR user explicitly accepts failures

---

#### 7. REPORT

**Trigger:** Verify phase passed

**Actions:**
- Summarize changes with file:line references
- Confirm DoD items satisfied
- Provide next steps (if any)
- Deliver per Output Contract (CLAUDE.md)

**Output:**
- Completion report matching Output Contract
- User-facing summary (no superlatives, factual)

**Quality Gate:** User confirms task complete OR no follow-up questions

---

## Agent Handoff Contracts

### Planner Agent (EnterPlanMode)

**INPUT:**
- Task description
- Codebase context from EXPLORE phase
- User requirements (structured or raw)

**EXPECTED OUTPUT:**
- Written plan file with:
  - Approach description
  - Files to modify (with rationale)
  - Risks/trade-offs
  - Testing strategy
- Ready for user approval via ExitPlanMode

**HANDOFF TRIGGER:** User approves plan

---

### Architect Agent (repo-recon skill)

**INPUT:**
- Repository path
- Analysis goals (architecture map, pattern discovery, dependency graph)

**EXPECTED OUTPUT:**
- Architecture documentation (≤ 200 lines)
- Key patterns, conventions, folder structure
- Technology stack, frameworks, build tools

**HANDOFF TRIGGER:** Architecture understanding sufficient for PLAN phase

---

### Implementer Agent (general-purpose, Bash)

**INPUT:**
- Subtask from task list (via TaskGet)
- Plan/requirements
- Files to modify

**EXPECTED OUTPUT:**
- Code changes following existing patterns
- Zero new security vulnerabilities
- File:line references for all changes

**HANDOFF TRIGGER:** Subtask marked completed AND acceptance criteria met

---

### Critic Agent (reviewer skill)

**INPUT:**
- Modified files (from git diff or staging area)
- Original requirements
- Security checklist

**EXPECTED OUTPUT:**
- Pass/Fail verdict
- List of issues (security, correctness, style)
- Recommendations

**HANDOFF TRIGGER:** All issues resolved OR user accepts with known issues

---

### Prompt Engineer Agent (prompt-lint skill)

**INPUT:**
- Skill file or prompt template
- Target use case

**EXPECTED OUTPUT:**
- Validation report (clarity, specificity, token efficiency)
- Improvement suggestions

**HANDOFF TRIGGER:** Prompt quality acceptable OR revisions applied

---

### Team Lead Agent (Agent Teams — `.claude/agents/team-lead.md`)

**INPUT:**
- Decomposed task list (from DECOMPOSE phase)
- File-to-workstream mapping
- Acceptance criteria per subtask

**EXPECTED OUTPUT:**
- Teammate spawn confirmations
- Shared task list with all tasks completed
- Handoff report: files modified per teammate, issues encountered
- No file ownership violations

**HANDOFF TRIGGER:** All teammate tasks completed AND handoff report delivered

**HANDOFF CONTRACT:**
- Orchestrator delegates IMPLEMENT entirely to team lead
- Team lead owns task coordination, teammate messaging, blocker resolution
- Orchestrator regains control at VERIFY (verification independence: verifier ≠ implementer)
- Team lead MUST NOT write code — delegation only

---

## Agent Teams Coordination

**When IMPLEMENT selects Path C (Agent Teams):**

```
ORCHESTRATOR                    TEAM LEAD
    │                               │
    ├── Hands off task list ───────>│
    │   + file ownership map        │
    │   + acceptance criteria       ├── Spawns teammates
    │                               ├── Assigns file ownership
    │   (Orchestrator waits)        ├── Monitors shared task list
    │                               ├── Resolves blockers
    │                               ├── Verifies completion
    │<── Handoff report ───────────┤
    │                               │
    ├── VERIFY phase (independent)  │
    ├── REPORT phase                │
    └── Done                        │
```

**Key Rules:**
1. Orchestrator MUST NOT intervene during team lead's execution
2. Team lead MUST NOT perform VERIFY — that's orchestrator's responsibility
3. Teammates inherit CLAUDE.md rules automatically (no separate safety config)
4. Maximum 5 teammates per team (see team-lead.md for sizing guide)
5. If team lead reports blockers, orchestrator decides: resolve or abort

**Guardrails (실험적 기능 방어):**
- **Context Compaction 대비:** 팀 세션은 짧게 유지. 팀원당 5-6개 태스크 상한
- **in-process 모드 필수:** tmux 모드는 메일박스 폴링 버그로 사용 금지 (settings.json 강제)
- **배치 스폰:** 팀원 동시 스폰은 최대 2명씩 (cascade 실패 방지)
- **Resume 금지:** 팀 세션에서는 `/resume` 대신 새 세션 시작 선호
- **Quality Hooks 활성:** `TeammateIdle` + `TaskCompleted` hook이 미완료 작업/보안 위반 검출
- **복구 절차:** 팀 상태 이상 시 `~/.claude/teams/` + `~/.claude/tasks/` 확인 → 고아 팀원 정리 → 재할당
- 상세 방어 프로토콜은 `team-lead.md`의 "Known Limitations & Defenses" 섹션 참조

---

## Skill Loading Rules

### Core Principle

⚠️ **NEVER load skills always-on.** Load just-in-time based on workflow stage triggers only.

### Loading Decision Matrix

| Workflow Stage | Load Skill(s)                     | Condition                                      |
|----------------|-----------------------------------|------------------------------------------------|
| INTAKE         | requirements-compiler             | Request is unstructured/vague                  |
| EXPLORE        | repo-recon                        | New codebase OR architecture unknown           |
| PLAN           | task-decomposer                   | Task has 3+ subtasks                           |
| IMPLEMENT      | (none - use agents)               | Execution via Task tool, not skills            |
| VERIFY         | reviewer, testing-harness         | Always load for quality audit                  |
| Meta (authoring)| prompt-lint                      | Creating/updating skill files                  |

### Simultaneous Load Limit

- **Maximum:** 2 skills loaded concurrently
- **Justification Required:** If > 2, document token cost reason
- **Unload:** Clear mental model of skill after stage completes

### Anti-Patterns

❌ Load all skills at workflow start
❌ Keep reviewer loaded during IMPLEMENT
❌ Auto-chain skills without explicit stage transition
❌ Load skills "just in case" for future stages

### Correct Pattern

✅ Load requirements-compiler in INTAKE → unload before EXPLORE
✅ Load reviewer + testing-harness together in VERIFY (justified: both needed for quality gate)
✅ Load task-decomposer in PLAN if subtask count ≥ 3 → unload before IMPLEMENT

---

## Quality Gates

### Gate 1: Requirements Clarity (INTAKE → EXPLORE)

**Criteria:**
- [ ] User request understood OR clarifying questions answered
- [ ] Acceptance criteria identifiable
- [ ] Scope bounded (no open-ended "improve performance" without metrics)

**Failure Action:** Stop, ask questions (max 3), wait for user input

---

### Gate 2: Exploration Sufficiency (EXPLORE → PLAN)

**Criteria:**
- [ ] Relevant files identified
- [ ] Existing patterns understood
- [ ] Dependencies mapped
- [ ] OR exploration exhausted (no more leads)

**Failure Action:** Extend search with higher thoroughness OR ask user for pointers

---

### Gate 3: Plan Approval (PLAN → DECOMPOSE/IMPLEMENT)

**Criteria:**
- [ ] User approved plan via ExitPlanMode OR
- [ ] Simple task (no plan needed) confirmed by user

**Failure Action:** Revise plan, wait for approval

---

### Gate 4: Implementation Integrity (IMPLEMENT → VERIFY)

**Criteria:**
- [ ] All subtasks completed
- [ ] No failing tests (if tests exist)
- [ ] No unresolved errors in implementation
- [ ] Files exist at expected paths

**Failure Action:** Fix issues, re-run subtasks, report blockers to user

---

### Gate 5: Verification Passed (VERIFY → REPORT)

**Criteria:**
- [ ] Reviewer passed OR user accepted findings
- [ ] Testing-harness passed OR no tests required
- [ ] Self-check (CLAUDE.md) all items passed
- [ ] No secrets in staging area

**Failure Action:** Fix issues, re-verify, or escalate to user

---

### Gate 6: Delivery Confirmation (REPORT → Done)

**Criteria:**
- [ ] User confirms completion OR
- [ ] Deliverable matches Output Contract (CLAUDE.md)
- [ ] DoD checklist satisfied

**Failure Action:** Address user feedback, iterate

---

## Output Contract

**All outputs inherit from CLAUDE.md Output Contract.**

**Orchestrator-Specific Additions:**

1. **Workflow Reports:**
   - Stage transitions logged (which stage, trigger, output)
   - Skill load/unload events tracked
   - Quality gate pass/fail results documented

2. **Multi-Agent Coordination:**
   - Agent assignments clear (which agent handled which subtask)
   - Handoff artifacts referenced (e.g., "Plan approved in plan.md:15-42")
   - Dependency resolution order documented

3. **Token Usage:**
   - Skills loaded listed (name + stage)
   - Agent invocations counted
   - Justification if > 2 skills loaded concurrently

4. **Failure Transparency:**
   - If quality gate fails, report which gate, why, and recovery action
   - If agent fails, report agent type, subtask, error, and mitigation

## Definition of Done

**Orchestrator Task Complete When:**

- [ ] All workflow stages executed in order (or skipped with justification)
- [ ] All quality gates passed OR user explicitly accepted failures
- [ ] All subtasks (if decomposed) marked completed
- [ ] CLAUDE.md DoD checklist satisfied
- [ ] Workflow report delivered to user
- [ ] All loaded skills unloaded from mental context

**NOT Done If:**

- Any quality gate failed without user acceptance
- Subtasks blocked or in_progress
- Secrets detected in staging area
- User has unresolved questions
- Output Contract violated

## Self-check

**Run before REPORT stage:**

```
1. WORKFLOW INTEGRITY
   [ ] All required stages executed?
   [ ] Quality gates passed or failures justified?
   [ ] Stage outputs conform to handoff contracts?

2. SKILL LOADING DISCIPLINE
   [ ] Only necessary skills loaded? (List: _______)
   [ ] Max 2 concurrent? If > 2, justified?
   [ ] Skills unloaded after stage completion?

3. AGENT COORDINATION
   [ ] Agents assigned to appropriate subtasks?
   [ ] Handoff artifacts verified before next stage?
   [ ] No parallel execution of dependent tasks?

4. SECURITY & SAFETY (from CLAUDE.md)
   [ ] No secrets in code/commits/logs?
   [ ] No destructive commands without approval?
   [ ] Reviewer skill passed OR user accepted risks?

5. TOKEN ECONOMY
   [ ] Used Task tool (Explore) vs inline loops?
   [ ] Avoided redundant skill loads?
   [ ] Parallel tool calls used where independent?

6. OUTPUT CONTRACT
   [ ] File:line references included?
   [ ] DoD checklist satisfied?
   [ ] User can verify results?
```

**Action:** If ANY check fails, halt REPORT, fix issue, re-verify.

---

## Workflow Examples

### Example 1: Simple Bug Fix (Bypass Orchestrator)

```
User: "Fix typo in README line 42"
→ Complexity: Simple (1-line change)
→ Decision: Skip INTAKE/EXPLORE/PLAN/DECOMPOSE
→ Execute: Read README, Edit line 42, VERIFY (self-check), REPORT
→ Skills Loaded: None
→ Agents Invoked: None (inline)
```

---

### Example 2: Add Authentication Feature (Agent Teams Path)

```
User: "Add JWT authentication to the API"

INTAKE → Load requirements-compiler → Structured requirements → Gate 1: ✅
EXPLORE → Task tool (Explore) → Auth patterns, middleware structure → Gate 2: ✅
PLAN → EnterPlanMode → Plan approved by user → Gate 3: ✅
DECOMPOSE → task-decomposer → 5 subtasks (middleware, routes, models, tests, docs)

IMPLEMENT (Path C — Agent Teams):
  → Hand off to team-lead agent
  → Team lead spawns 3 teammates:
    - implementer-1: OWNS middleware.ts, auth-routes.ts
    - implementer-2: OWNS user-model.ts, auth-config.ts
    - critic-1: READ-ONLY all files (security focus)
  → Shared task list manages coordination
  → Team lead handoff report: all 5 tasks completed, no conflicts
  → Gate 4: ✅

VERIFY → reviewer + testing-harness (independent of team) → Gate 5: ✅
REPORT → JWT auth in 4 files, 3 teammates, 5 tasks → Gate 6: ✅ User confirms
```

---
**End of ORCHESTRATOR.md** • Systematic multi-agent coordination for complex tasks
