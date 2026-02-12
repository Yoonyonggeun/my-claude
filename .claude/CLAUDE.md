# Claude Project Operating Manual

## Purpose

This repository establishes a production-grade Claude Code workflow emphasizing **Safety**, **Token Economy**, and **Verifiable Execution**.

## Operating Rules

### Security & Safety

**PROHIBITED ACTIONS:**
- Writing secrets, API keys, tokens, or credentials in any form (code, logs, commits)
- Executing `rm -rf`, `git push --force`, `git reset --hard` without explicit user approval
- Installing packages or making network calls without permission
- Modifying `.git/config` or authentication files
- Committing `.env`, `credentials.json`, or files containing sensitive data

**REQUIRED BEHAVIORS:**
- Always read existing code before proposing modifications
- Verify file paths exist before operations
- Use `--dry-run` flags when available for destructive operations
- Ask clarifying questions before ambiguous tasks (max 3 questions via AskUserQuestion)
- Validate no secrets in staging area before commits

### External Network Policy

- **Default:** External network access DISABLED
- **Whitelist:** Web searches and documentation lookups require user approval
- **Package installation:** Requires explicit permission per session

## Token Economy

**CLAUDE.md Constraints:**
- **Hard Limit:** ≤ 200 lines (this document)
- **Strategy:** Keep core rules minimal; move detailed procedures to `/skills/`
- **Overflow Rule:** If section exceeds 30 lines, extract to dedicated skill

**Skill Loading:**
- ⚠️ **CRITICAL:** NEVER configure skills as always-on (no `alwaysAllow` in settings)
- Load skills just-in-time based on task triggers only
- Prefer Task tool with specialized agents over inline skill loading
- Unload mental context of skills after task completion

**Cost Optimization:**
- Use `Task` tool with `Explore` agent for codebase searches (not inline Grep loops)
- Read files once; avoid redundant reads
- Parallel tool calls for independent operations

## Workflow

```
1. EXPLORE    → Understand codebase/requirements (Task tool w/ Explore agent)
2. PLAN       → Design approach (EnterPlanMode for non-trivial tasks)
3. IMPLEMENT  → Execute changes (follow Output Contract)
4. VERIFY     → Run self-check (see Self-check section)
5. REPORT     → Deliver result with DoD confirmation
```

**Task Complexity Decision:**
- **Simple** (1-3 line change, obvious fix) → Skip PLAN, proceed to IMPLEMENT
- **Non-trivial** (new feature, multi-file, architectural) → MUST use EnterPlanMode
- **Research** (codebase exploration, "how does X work?") → Task tool with Explore agent

## Execution Mode Decision

| Criteria        | Single Session          | Subagents (Task tool)       | Agent Teams                    |
|-----------------|-------------------------|-----------------------------|--------------------------------|
| Scope           | 1-3 files               | Focused subtasks            | 3+ independent workstreams     |
| Communication   | N/A                     | Results only (return value) | Mutual messaging + shared tasks|
| Token Cost      | Lowest                  | Medium                      | Highest                        |
| Coordination    | None                    | Parent orchestrates         | Team lead delegates            |
| Best For        | Quick fixes, small edits| Research, isolated changes  | Full features, refactoring     |

**Selection Rules:**
- Default to **Single Session** unless task clearly exceeds scope
- Use **Subagents** for parallel research or isolated file changes
- Use **Agent Teams** only when 3+ teammates needed with inter-task dependencies
- Agent Teams require `team-lead` agent for coordination (see `.claude/agents/team-lead.md`)

**Agent Teams Role Binding:**
- Team lead MUST follow `.claude/agents/team-lead.md` rules
- Teammates MUST be spawned with matching `.claude/agents/{role}.md` as system context
- Available roles: `planner`, `architect`, `implementer`, `critic`, `prompt-engineer`
- Spawn prompt must include: "Follow the rules defined in .claude/agents/{role}.md"
- Teammates use Sonnet by default; only lead uses Opus (cost optimization)

## Skill Loading Rules

⚠️ **CRITICAL PRINCIPLE:** Skills are NOT loaded always-on. Load only when trigger condition is met.

**Available Skills:** (in `.claude/skills/`)

| Skill File                 | Load Trigger                                      | Purpose                          |
|----------------------------|---------------------------------------------------|----------------------------------|
| requirements-compiler.md   | User provides raw requirements/feature request    | Extract structured specs         |
| task-decomposer.md         | Complex task needs breakdown into subtasks        | Generate actionable task list    |
| repo-recon.md              | New repository/codebase analysis needed           | Map architecture & patterns      |
| testing-harness.md         | Test creation/execution required                  | Generate & run tests             |
| reviewer.md                | Code review requested or pre-commit check         | Quality & security audit         |
| prompt-lint.md             | Prompt/skill authoring or quality check           | Validate prompt engineering      |

**Loading Principles:**
1. **Lazy Load:** Invoke skill only when trigger condition explicitly met
2. **Explicit Invocation:** Use `Skill` tool with exact skill name
3. **Single Responsibility:** One skill per task phase
4. **No Chaining:** Don't auto-load dependent skills; user/workflow decides
5. **Minimal Context:** Load skill, execute, unload mental model

## Output Contract

**For All Deliverables:**

1. **Code Changes:**
   - Include file path with line numbers (e.g., `src/auth.ts:42`)
   - Read existing code before editing (mandatory)
   - Preserve existing patterns/style
   - Zero OWASP Top 10 vulnerabilities introduced
   - No secrets in code or comments

2. **Documentation:**
   - Always-on docs: ≤ 200 lines
   - Use headings, tables, code blocks for scanability
   - Include examples for non-obvious procedures
   - Avoid superlatives and unnecessary praise

3. **Git Commits (when requested):**
   - Check `git log` to match existing commit style
   - Stage only relevant files (avoid `git add .`)
   - Commit message format:
     ```
     <type>: <short summary>

     <optional detailed explanation>

     Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
     ```
   - Never skip hooks unless user explicitly requests `--no-verify`

4. **Pull Requests (when requested):**
   - Title ≤ 70 characters
   - Body structure:
     ```markdown
     ## Summary
     - <bullet points>

     ## Test Plan
     - [ ] <verification checklist>

     🤖 Generated with [Claude Code](https://claude.com/claude-code)
     ```

## Definition of Done

**Task Complete When:**
- [ ] All acceptance criteria met (from PLAN phase or user request)
- [ ] Self-check passed (all items below)
- [ ] No uncommitted sensitive data in working directory (`git status` clean of secrets)
- [ ] Tests pass (if testing-harness.md was invoked)
- [ ] User explicitly confirms completion OR deliverable matches Output Contract

**NOT Done If:**
- Tests failing
- Implementation partial due to blockers
- Unresolved errors encountered
- Required files not found
- Security check failed

## Self-check

**Run before marking task complete:**

```
1. SECURITY
   [ ] No secrets/keys/tokens in code, comments, logs, or commits?
   [ ] No new injection vectors (SQL, XSS, command injection, path traversal)?
   [ ] File permissions unchanged unless required?
   [ ] No destructive commands executed without approval?

2. CORRECTNESS
   [ ] Read existing code before changes?
   [ ] Changes match user request exactly?
   [ ] Edge cases considered? (List or N/A)
   [ ] No breaking changes to existing functionality?

3. TOKEN ECONOMY
   [ ] Used Task tool for exploration vs inline Grep/Read loops?
   [ ] Loaded only necessary skills? (List or None)
   [ ] Avoided redundant file reads?
   [ ] Parallel tool calls used for independent operations?

4. VERIFIABILITY
   [ ] Output includes file:line references?
   [ ] Changes reversible via git?
   [ ] User can validate result without running code?
   [ ] DoD checklist items satisfied?
```

**Action:** If ANY check fails, fix issue before reporting completion.
