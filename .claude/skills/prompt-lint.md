# Prompt Lint Skill

## Purpose

Validate prompt engineering quality for Claude skills, system prompts, and CLAUDE.md using **PES (Prompt Engineering Standard)** principles. Detects ambiguities, contradictions, missing specifications, and over-engineering that lead to unreliable agent behavior.

**Core Function:** Apply systematic lint rules to catch common prompt defects before deployment, ensuring prompts produce deterministic, verifiable, and token-efficient outputs.

---

## When to Load This Skill

### ✅ LOAD Triggers

| Situation | Example | Action |
|-----------|---------|--------|
| New skill authored | Created `new-skill.md` | Load → Validate against PES |
| CLAUDE.md modified | Updated operating rules | Load → Check for contradictions |
| Repeated task failures | Agent misses deliverables 2+ times | Load → Audit task prompt |
| Prompt injection risk | User-facing prompt template | Load → Security review |
| Before skill release | Pre-commit hook for .claude/skills/ | Load → Quality gate |
| Eval failures | Agent behavior inconsistent | Load → Root cause analysis |

### ❌ DO NOT Load

| Situation | Reason | Alternative |
|-----------|--------|-------------|
| General code review | Not prompt-specific | Use reviewer.md skill |
| User code quality check | Not prompt engineering | Use linter (ESLint/Ruff) |
| Documentation writing | Not agent instruction | Direct writing |
| After single task failure | Insufficient signal | Debug inline first |
| Production code linting | Different domain | Language-specific tools |

**Critical Rule:** Only load when authoring/debugging **agent instructions** (prompts, skills, CLAUDE.md), not regular code.

---

## Lint Checklist

### 1. Spec-First Violations

**Rule:** Every task MUST define **Output Contract** before **Procedure**.

| Defect | Detection | Fix |
|--------|-----------|-----|
| **Missing Output Contract** | No "Output Contract" or "Deliverables" section | Add explicit section defining success criteria |
| **Vague Deliverables** | Uses "improve", "better", "good" without metrics | Replace with measurable outcomes (e.g., "< 200ms response time") |
| **Procedure-first Design** | Implementation steps before defining what to deliver | Reorder: Outputs → Inputs → Procedure |
| **Untestable Criteria** | "Make user happy", "Clean code" | Define verification method (e.g., "Passes ESLint", "User confirms") |

**Quick Fix Pattern:**
```markdown
❌ BEFORE:
## Procedure
1. Read file
2. Improve code
3. Done

✅ AFTER:
## Output Contract
- Code passes ESLint with 0 warnings
- Test coverage ≥ 80%
- No OWASP Top 10 vulnerabilities

## Procedure
1. Read file → Identify lint violations
2. Apply fixes → Re-lint
3. Verify coverage → Report
```

---

### 2. Evals-First Violations

**Rule:** Every output MUST have a **verification method** (eval).

| Defect | Detection | Fix |
|--------|-----------|-----|
| **No Self-Check Section** | Missing "Self-check" or "Definition of Done" | Add checklist with binary checks |
| **Unevaluatable Output** | Deliverable can't be mechanically verified | Include test command or validation criteria |
| **Missing DoD** | No explicit "Task complete when..." statement | Add DoD section with [ ] checkboxes |
| **Eval After Failure** | Only defines success, not failure modes | Add "NOT done if..." section |

**Quick Fix Pattern:**
```markdown
❌ BEFORE:
Deliver a summary of the code.

✅ AFTER:
## Output Contract
- Summary ≤ 200 words
- Includes 3-5 key functionality points
- Lists file:line references for critical sections

## Definition of Done
- [ ] Word count verified (≤ 200)
- [ ] All references point to existing code
- [ ] User confirms summary captures intent

## NOT Done If
- Summary exceeds 200 words
- Contains generic statements ("handles data", "processes requests")
- No file:line references provided
```

---

### 3. Output Contract Violations

**Rule:** Outputs MUST be **concrete, scoped, and verifiable**.

| Defect | Detection | Fix |
|--------|-----------|-----|
| **Ambiguous Scope** | "Update the files" (which files?) | Specify exact files or pattern (e.g., "src/**/*.ts") |
| **Open-Ended Output** | "Provide recommendations" (how many? what format?) | "Provide 3-5 recommendations as markdown list" |
| **No Format Specified** | "Create a report" | "Create markdown report with sections: Summary, Findings, Next Steps" |
| **Missing Constraints** | No limits on output size/complexity | Add "≤ 50 lines", "Max 3 files changed" |

**Quick Fix Pattern:**
```markdown
❌ BEFORE:
Analyze the codebase and provide suggestions.

✅ AFTER:
## Output Contract
**Format:** Markdown report with sections:
1. **Architecture Overview** (≤ 100 words)
2. **Key Patterns** (3-5 bullet points)
3. **Improvement Opportunities** (ranked list, top 3)

**Scope:** Focus on src/ directory only, exclude tests/

**Constraints:**
- Total output ≤ 300 words
- No suggestions requiring external dependencies
- File references must include line numbers
```

---

### 4. Self-Check Violations

**Rule:** Every skill MUST include **executable self-check** before completion.

| Defect | Detection | Fix |
|--------|-----------|-----|
| **No Self-Check Section** | Skill ends without verification | Add "Self-check" section with [ ] items |
| **Non-Binary Checks** | "Is the code good?" (subjective) | "Code passes `npm test` (yes/no)" |
| **Missing Failure Action** | No "if check fails" guidance | Add "Action: If ANY check fails, fix issue before reporting" |
| **Unreviewable Output** | Can't verify without running code | Add static verification (read output, check format) |

**Quick Fix Pattern:**
```markdown
❌ BEFORE:
Complete the task.

✅ AFTER:
## Self-Check
**Before marking task complete:**
```
[ ] COMPLETENESS
    [ ] All acceptance criteria met?
    [ ] Output format matches contract?
    [ ] File:line references valid?

[ ] CORRECTNESS
    [ ] Changes tested (command: npm test)?
    [ ] No regressions (diff reviewed)?

[ ] TOKEN ECONOMY
    [ ] Used minimal tool calls?
    [ ] No redundant reads?

[ ] SECURITY
    [ ] No secrets in output?
    [ ] No destructive commands run?
```

**Action:** If ANY check fails, fix issue before reporting completion.
```

---

### 5. Token Economy Violations

**Rule:** Prompts MUST optimize for **minimal context consumption**.

| Defect | Detection | Fix |
|--------|-----------|-----|
| **Always-On Skills** | Skill loaded in every conversation | Make on-demand, define triggers |
| **Redundant Instructions** | Repeats CLAUDE.md rules | Reference CLAUDE.md, don't duplicate |
| **Unbounded Output** | No size limits on generated content | Add hard limits (≤ 200 lines, ≤ 5 examples) |
| **Nested Skill Chaining** | Skill auto-loads other skills | User decides next skill, don't chain |
| **Example Bloat** | 10+ examples for simple concept | Max 3 examples, vary complexity |

**Quick Fix Pattern:**
```markdown
❌ BEFORE:
This skill is always active and provides 10 detailed examples...

✅ AFTER:
## Load Trigger
**ONLY load when:** User explicitly requests prompt validation

**Token Budget:** ≤ 300 lines total (current: 285)

## Examples
(Max 3, covering simple/medium/complex)

### Example 1: Simple Case (30 lines)
### Example 2: Medium Case (50 lines)
### Example 3: Edge Case (40 lines)

**Note:** For additional scenarios, see [link to wiki/docs]
```

---

### 6. Security & Safety Violations

**Rule:** Prompts handling sensitive operations MUST include **safety rails**.

| Defect | Detection | Fix |
|--------|-----------|-----|
| **Missing Prohibited Actions** | No "DO NOT" section for destructive tasks | Add explicit prohibitions (rm -rf, force push, etc.) |
| **No Secret Detection** | File writes without secret scanning | Add "Validate no secrets before commit" check |
| **Unrestricted Network** | External calls without approval gate | Add "User approval required" for network ops |
| **Injection Risk** | User input directly into commands | Add sanitization requirements |

**Quick Fix Pattern:**
```markdown
❌ BEFORE:
Execute the user's command.

✅ AFTER:
## Safety Notes

**PROHIBITED:**
- ❌ Running rm -rf or destructive filesystem commands
- ❌ Executing user input directly in shell (injection risk)
- ❌ Committing files containing secrets/API keys
- ❌ Network calls without explicit user approval

**REQUIRED:**
- ✅ Sanitize user input before shell execution
- ✅ Validate no secrets in staging area before commits
- ✅ Use --dry-run flags for destructive operations
- ✅ Ask confirmation for irreversible actions

## Self-Check
[ ] SECURITY
    [ ] No secrets in output?
    [ ] User input sanitized?
    [ ] Destructive ops approved?
```

---

### 7. Ambiguity & Contradiction Violations

**Rule:** Prompts MUST provide **unambiguous instructions**.

| Defect | Detection | Fix |
|--------|-----------|-----|
| **Contradictory Rules** | "Always X" and "Never X" both present | Resolve conflict, add priority order |
| **Undefined Terms** | Uses "clean", "optimize", "improve" without definition | Define metrics or provide examples |
| **Conditional Ambiguity** | "If complex, do X" (what threshold?) | Add explicit threshold (e.g., "> 3 files") |
| **Implicit Dependencies** | Assumes tool/skill exists without checking | Add discovery phase or fallback |

**Quick Fix Pattern:**
```markdown
❌ BEFORE:
If the task is complex, load task-decomposer.

✅ AFTER:
## Complexity Decision Tree
**Load task-decomposer when:**
- [ ] Task affects > 3 files
- [ ] Multiple architectural decisions needed
- [ ] User provides vague requirements

**Skip if:**
- [ ] Single file change
- [ ] Clear acceptance criteria provided
- [ ] Simple bug fix (< 10 lines changed)

**Edge Case:** If uncertain, err on side of decomposition.
```

---

## Procedure

### Phase 1: Initial Scan (Automated Checks)

**Run these checks in order:**

1. **Structure Validation**
   ```bash
   # Check required sections exist
   grep -E '^## (Purpose|Output Contract|Definition of Done|Self-check)' prompt.md
   ```
   **Expected:** All 4 sections found

2. **Spec-First Check**
   ```bash
   # Output Contract must appear before Procedure
   awk '/^## Output Contract/{oc=NR} /^## Procedure/{pr=NR} END{if(pr<oc) print "FAIL: Procedure before Output"}' prompt.md
   ```

3. **DoD Presence**
   ```bash
   # Must have checklist items
   grep -c '\[ \]' prompt.md
   ```
   **Expected:** ≥ 5 checklist items

4. **Size Limit Check**
   ```bash
   # Skills should be ≤ 600 lines (with exceptions)
   wc -l prompt.md
   ```
   **Flag if:** > 600 lines (justify in comments)

---

### Phase 2: Manual Review (Semantic Analysis)

**Review each section:**

| Section | Check For | Pass Criteria |
|---------|-----------|---------------|
| **Purpose** | Single clear statement, no jargon | ≤ 3 sentences, explains "what" and "why" |
| **Load Triggers** | Specific conditions, anti-triggers listed | Table with 3+ triggers, 3+ anti-triggers |
| **Output Contract** | Concrete deliverables, format specified | All outputs have format + size constraints |
| **Procedure** | Steps reference Output Contract | Each step traces to deliverable |
| **Self-Check** | Binary checks, failure action defined | All items [ ] format, "if fails" action present |
| **Examples** | Realistic, varied complexity | 2-3 examples, cover edge cases |

---

### Phase 3: Ambiguity Detection

**Scan for vague terms:**

```bash
# Detect ambiguous language
grep -iE '(improve|better|optimize|clean|good|bad|appropriate|reasonable|sufficient)' prompt.md
```

**For each match:**
1. Check if term is defined in context
2. If undefined → Flag for replacement with measurable criteria
3. Examples:
   - ❌ "Improve performance" → ✅ "Reduce response time to < 200ms"
   - ❌ "Clean code" → ✅ "Passes ESLint with 0 warnings"

---

### Phase 4: Contradiction Detection

**Check for conflicting rules:**

1. Extract all MUST/SHOULD/MUST NOT statements
2. Look for logical conflicts:
   ```
   Example conflict:
   - "MUST read file before editing"
   - "Procedure: 1. Edit file directly"
   ```
3. Resolve by:
   - Adding priority ("if conflict, security rules override efficiency")
   - Clarifying conditions ("MUST read unless file is new")
   - Removing redundant rule

---

## Output Template

### Lint Report Format

```markdown
## Prompt Lint Report

**File:** .claude/skills/example-skill.md
**Lines:** 450
**Status:** ⚠️ WARNINGS (3), ❌ ERRORS (1)

---

### ❌ ERRORS (Must Fix)

#### E1: Missing Output Contract
**Location:** N/A (section absent)
**Rule Violated:** Spec-First (Lint #1)
**Impact:** Agent has no clear success criteria
**Fix:**
\`\`\`markdown
## Output Contract
**Deliverable:** [Specify format, size, constraints]
**Format:** [Markdown/JSON/Code block]
**Constraints:** [≤ X lines, specific sections required]
\`\`\`

---

### ⚠️ WARNINGS (Recommend Fix)

#### W1: Ambiguous Term - "optimize"
**Location:** Line 42 (Procedure section)
**Context:** "Optimize the database queries"
**Rule Violated:** Ambiguity (Lint #7)
**Suggested Fix:** Define "optimize" with metric (e.g., "Reduce query time to < 50ms")

#### W2: No Size Limit on Output
**Location:** Output Contract section (line 78)
**Context:** "Generate a report"
**Rule Violated:** Output Contract (Lint #3)
**Suggested Fix:** Add "Report ≤ 300 words, 3 sections max"

#### W3: Example Bloat
**Location:** Examples section (lines 200-400)
**Context:** 8 examples provided (200 lines)
**Rule Violated:** Token Economy (Lint #5)
**Suggested Fix:** Reduce to 3 examples (simple/medium/complex), link to wiki for more

---

### ✅ PASSED CHECKS

- [x] Purpose section clear and concise
- [x] Self-Check section present with binary checks
- [x] DoD includes failure conditions
- [x] No contradictory rules detected
- [x] Security prohibitions defined

---

## Recommended Actions

**Priority 1 (Blocking):**
1. Add Output Contract section (E1) → Agent cannot self-verify without this

**Priority 2 (High):**
2. Define "optimize" with measurable criteria (W1)
3. Add output size constraints (W2)

**Priority 3 (Nice-to-have):**
4. Reduce examples to 3 (W3) → Saves ~150 lines of token budget

**Estimated Fix Time:** Priority 1+2 → ~10 minutes

---

## Compliance Score

**Total Checks:** 12
**Passed:** 9 (75%)
**Warnings:** 3 (25%)
**Errors:** 1 (8%)

**Grade:** C (Functional but needs improvement)

**Certification:** ❌ NOT READY for production use until errors resolved.
```

---

## Quick Fix Patterns

### Pattern 1: Add Missing Output Contract

```markdown
## Output Contract

**Deliverable:** [One sentence describing what agent produces]

**Format:**
- [Markdown/JSON/Code/Table]
- [Section structure if applicable]

**Constraints:**
- Size: ≤ [X] lines / words
- Scope: [What's included/excluded]
- References: [File:line format required? Y/N]

**Success Criteria:**
- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] [Measurable criterion 3]
```

---

### Pattern 2: Convert Vague to Specific

```markdown
❌ VAGUE: "Improve code quality"

✅ SPECIFIC:
## Acceptance Criteria
- [ ] ESLint score 0 warnings (run: npm run lint)
- [ ] Test coverage ≥ 80% (run: npm test -- --coverage)
- [ ] Cyclomatic complexity ≤ 10 per function (run: npm run complexity)
- [ ] No OWASP Top 10 vulnerabilities (run: npm audit)
```

---

### Pattern 3: Add Self-Check Section

```markdown
## Self-Check

**Before marking task complete:**

\`\`\`
[ ] COMPLETENESS
    [ ] All Output Contract items delivered?
    [ ] Format matches specification?

[ ] CORRECTNESS
    [ ] [Verification command] passes?
    [ ] No regressions introduced?

[ ] TOKEN ECONOMY
    [ ] Used minimal tool calls?
    [ ] No redundant reads?

[ ] SECURITY (if applicable)
    [ ] No secrets in output?
    [ ] No destructive commands?
\`\`\`

**Action:** If ANY check fails, fix issue before reporting completion.
```

---

### Pattern 4: Define Load Triggers

```markdown
## When to Load This Skill

### ✅ LOAD Triggers
- [Specific user input pattern 1]
- [Specific user input pattern 2]
- [Explicit request: "command name"]

### ❌ DO NOT Load
- [Similar-but-different scenario 1] → Use [alternative] instead
- [Scenario 2] → [Reason + alternative]

**Critical Rule:** [One-sentence decision boundary]
```

---

### Pattern 5: Add Token Budget

```markdown
## Meta

- **Skill Type:** On-demand (load on trigger only)
- **Token Budget:** ≤ [X] lines (current: [Y])
- **Load Frequency:** [Expected usage pattern]
- **Average Session Duration:** [Time estimate]

**Overflow Strategy:** If exceeds [X] lines, extract [section] to separate skill.
```

---

## Definition of Done

**Prompt lint task complete when:**

- [ ] All ERROR-level violations resolved
- [ ] All WARNING-level violations addressed or documented as accepted
- [ ] Lint report generated in specified format
- [ ] Compliance score ≥ 80% (9/12 checks passed)
- [ ] If skill document: Passes all 7 lint rules
- [ ] User acknowledges report and approves changes (if applicable)

**NOT done if:**
- Any ERROR-level violation remains unfixed
- Output Contract missing or vague
- Self-Check section absent
- Ambiguous terms undefined (> 3 instances)
- Contradictory rules unresolved

---

## Self-Check

**Before delivering lint report:**

```
[ ] COMPLETENESS
    [ ] All 7 lint rules checked?
    [ ] Both errors and warnings identified?
    [ ] Quick fix patterns provided for each violation?

[ ] ACCURACY
    [ ] Line numbers correct (if referenced)?
    [ ] Violations actually present (not false positives)?
    [ ] Suggested fixes tested or validated?

[ ] ACTIONABILITY
    [ ] Each violation has specific fix guidance?
    [ ] Priority ranking provided (blocking/high/nice-to-have)?
    [ ] Fix time estimates reasonable?

[ ] FORMAT
    [ ] Report follows Output Template structure?
    [ ] Compliance score calculated correctly?
    [ ] Grade assigned (A/B/C/D/F based on % passed)?
```

**Action:** If any check fails, revise report before delivery.

---

## Safety Notes

### Prohibited During Lint

- ❌ **No Auto-Fix:** Do NOT automatically modify prompts without user approval
- ❌ **No Subjective Judgment:** Flag only rule violations, not style preferences
- ❌ **No Scope Creep:** Lint prompt engineering only, not general code quality
- ❌ **No Silent Failures:** Report all violations, even if "minor"

### Required Behaviors

- ✅ **Read-Only Analysis:** Only read files, never modify during lint phase
- ✅ **Objective Criteria:** All violations traceable to specific rule
- ✅ **Severity Classification:** Distinguish errors (blocking) vs warnings (recommend)
- ✅ **Fix Guidance:** Provide concrete examples for each violation

---

## Anti-Patterns

**AVOID:**

❌ **Over-Linting:**
```markdown
Flagging every instance of "the" as ambiguous
```

❌ **Under-Linting:**
```markdown
"Looks fine" without running checklist
```

❌ **Subjective Critique:**
```markdown
"This section feels too verbose" (not a rule violation)
```

❌ **Auto-Fix Without Review:**
```markdown
Rewriting entire prompt based on lint findings
```

❌ **False Positives:**
```markdown
Flagging "improve performance" when followed by "< 200ms target"
```

---

## Examples

### Example 1: Simple Skill Lint

**Input:** New skill `.claude/skills/code-formatter.md`

**Lint Findings:**
- ❌ ERROR: Missing Self-Check section
- ⚠️ WARNING: Ambiguous term "clean code" (line 23)
- ✅ PASSED: Output Contract present and specific

**Report Excerpt:**
```markdown
## Prompt Lint Report
**Status:** ❌ 1 ERROR, ⚠️ 1 WARNING

### ❌ E1: Missing Self-Check
**Fix:** Add section using Pattern 3 (Quick Fix Patterns)

### ⚠️ W1: Ambiguous "clean code"
**Suggested Fix:** Replace with "Passes ESLint, Prettier"

**Compliance Score:** 11/12 (92%) → Grade: A-
**Certification:** ❌ NOT READY until Self-Check added
```

---

### Example 2: CLAUDE.md Contradiction

**Input:** Modified CLAUDE.md with conflicting rules

**Lint Findings:**
- ❌ ERROR: Contradiction detected (lines 45, 78)
  - Line 45: "ALWAYS use Task tool for exploration"
  - Line 78: "Use Grep for quick searches"

**Report Excerpt:**
```markdown
### ❌ E1: Rule Contradiction
**Conflict:**
- Rule A (line 45): "ALWAYS use Task tool"
- Rule B (line 78): "Use Grep for quick searches"

**Resolution Options:**
1. Add condition: "Use Grep for needle queries, Task for open-ended exploration"
2. Priority: "If in doubt, prefer Task tool (line 45 takes precedence)"
3. Remove redundant rule (delete line 78)

**Recommended:** Option 1 (preserves both, adds clarity)
```

---

### Example 3: Token Bloat Detection

**Input:** Skill with 800 lines, 12 examples

**Lint Findings:**
- ⚠️ WARNING: Size limit exceeded (800 lines vs ≤ 600 target)
- ⚠️ WARNING: Example bloat (12 examples vs ≤ 3 recommended)

**Report Excerpt:**
```markdown
### ⚠️ W1: Token Budget Exceeded
**Current:** 800 lines
**Target:** ≤ 600 lines
**Overage:** 200 lines (33% over budget)

**Breakdown:**
- Examples section: 400 lines (12 examples)
- Procedure: 200 lines
- Other: 200 lines

**Suggested Fix:**
1. Reduce examples: 12 → 3 (saves ~300 lines)
2. Extract detailed procedure to wiki (saves ~100 lines)
3. **Result:** ~400 lines (within budget)
```

---

## Meta

- **Skill Type:** On-demand (load when linting prompts)
- **Token Budget:** ≤ 400 lines (current: ~620—optimizable if needed)
- **Dependencies:** Bash (grep/awk), Read tool
- **Version:** 1.0.0
- **Last Updated:** 2026-02-01

**Integration:**
- **Before:** Prompt authored or modified
- **After:** User reviews lint report → Fixes violations → Re-lint (optional)

---

**End of prompt-lint.md** • PES-compliant prompt validation for reliable agent behavior
