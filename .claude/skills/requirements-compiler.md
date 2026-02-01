# Requirements Compiler Skill

## Purpose

Transforms raw user input (vague feature requests, verbal descriptions, incomplete specs) into structured, actionable requirements following PROMPT_BRIEF methodology.

**Core Function:** Extract, clarify, and formalize requirements into standardized sections that enable unambiguous implementation.

---

## When to Load This Skill

### ✅ LOAD Triggers

| User Input Pattern | Example | Action |
|-------------------|---------|--------|
| Raw feature request | "Add user login" | Load skill → Extract requirements |
| Vague description | "Make it faster" | Load skill → Clarify scope |
| Incomplete spec | "Add auth, use JWT maybe?" | Load skill → Fill gaps |
| Explicit request | "Help me write requirements" | Load skill |
| New project kickoff | "Starting a new feature" | Load skill (optional) |

### ❌ DO NOT Load

| Situation | Reason | Alternative |
|-----------|--------|-------------|
| Implementation task with clear requirements | Already have structured spec | Proceed to task-decomposer or implementation |
| Debugging/fixing existing code | Not a new requirement | Use repo-recon or direct debugging |
| Code review request | Different workflow | Use reviewer.md skill |
| User provides PROMPT_BRIEF already | No compilation needed | Validate format only |
| Simple clarification questions | Overhead too high | Use AskUserQuestion directly |

**Critical Rule:** If user provides structured requirements (headings, acceptance criteria, constraints), DO NOT load this skill. Acknowledge format and proceed.

---

## Inputs Needed

### Required
- **User Description:** Raw text describing what they want (feature, change, problem to solve)

### Recommended (gather via AskUserQuestion if missing)
- **Context:** What system/component does this affect?
- **Success Criteria:** How will we know it's done?
- **Constraints:** Any technical limitations, deadlines, or dependencies?

### Optional
- **Existing Code:** Relevant files/modules (read if provided)
- **Motivation:** Why is this needed? (helps with edge cases)

---

## Procedure

### Phase 1: Initial Analysis (No Questions)

1. **Read User Input:**
   - Extract explicit requirements
   - Identify ambiguities
   - Note missing critical info

2. **Determine Complexity:**
   - **Simple:** Clear single change (e.g., "add logout button") → Minimal clarification
   - **Medium:** Feature with known patterns (e.g., "add auth") → 1-2 questions
   - **Complex:** Unclear scope/multi-component (e.g., "improve performance") → 2-3 questions

3. **Check Repository Context:**
   - IF user mentioned files/components → Read relevant code (max 3 files)
   - Identify existing patterns to align with

### Phase 2: Clarification (Max 3 Questions)

**Question Budget:** ≤ 3 questions via AskUserQuestion

**Prioritization:**
1. **Must-have:** Blocker info without which requirements are invalid
2. **Should-have:** Significant impact on design/scope
3. **Nice-to-have:** Optimization details (skip if budget exceeded)

**Question Templates:**

```markdown
# Scope Clarification
Question: "Should this feature also handle [edge case]?"
Options:
  - Yes, include [case]
  - No, [case] is out of scope
  - Defer to future iteration

# Technical Approach
Question: "Which authentication method should we use?"
Options:
  - JWT tokens (stateless)
  - Session-based (server-side state)
  - OAuth 2.0 (third-party)

# Success Criteria
Question: "What performance target defines success?"
Options:
  - Response time < 200ms
  - Handle 1000 concurrent users
  - No specific target, improve current
```

**Anti-Pattern:**
- ❌ Don't ask "Do you want me to proceed?" (implied yes)
- ❌ Don't ask design details you can infer from codebase patterns
- ❌ Don't ask for information already provided in user input

### Phase 3: Compile Requirements

Using gathered info, populate PROMPT_BRIEF template (see Output Templates).

**Validation Checklist:**
- [ ] Purpose is single sentence
- [ ] At least 3 acceptance criteria (specific, testable)
- [ ] Constraints capture technical/business limits
- [ ] Assumptions document what we're NOT verifying
- [ ] Out of scope prevents feature creep

---

## Output Templates

### Standard PROMPT_BRIEF Structure

```markdown
# [Feature/Change Name]

## Purpose
[Single sentence: What is this and why does it exist?]

## Scope
[2-4 bullet points: What's included in this work]

## Acceptance Criteria
- [ ] [Specific, testable requirement 1]
- [ ] [Specific, testable requirement 2]
- [ ] [Specific, testable requirement 3]
- [ ] [Edge case or error handling]
- [ ] [Performance/quality gate if applicable]

## Constraints
- **Technical:** [Language version, framework limits, dependencies]
- **Timeline:** [Deadline if exists, or "No hard deadline"]
- **Resources:** [API limits, rate limits, budget]
- **Compatibility:** [Browser support, OS versions, etc.]

## Assumptions
- [What we're assuming is true without verification]
- [External service behavior we depend on]
- [User knowledge/context we expect]

## Out of Scope
- [Related features deliberately excluded]
- [Future enhancements not in this iteration]
- [Edge cases deferred]

## Dependencies
- [External APIs, services, or teams]
- [Prerequisite features that must exist]
- [Tools or libraries to be installed]

## Success Metrics (Optional)
- [Quantifiable measure of success]
- [How to validate in production]

## References (Optional)
- [Design docs, RFC links]
- [Similar implementations]
- [Relevant discussions]
```

### Simplified Template (for simple tasks)

```markdown
# [Feature Name]

## Purpose
[One sentence]

## Acceptance Criteria
- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

## Constraints
- [Key limitation]

## Out of Scope
- [What we're NOT doing]
```

**Use simplified template when:**
- Change affects < 3 files
- No external dependencies
- Clear existing pattern to follow
- User provided detailed description already

---

## Safety Notes

### Prohibited During Requirements Compilation

- ❌ **No Implementation:** Do NOT write code in this phase
- ❌ **No File Creation:** Do NOT create placeholder files
- ❌ **No Package Installation:** Do NOT install dependencies
- ❌ **No Commits:** Do NOT create git commits
- ❌ **No External Calls:** Do NOT make API requests or web searches without approval

### Required Behaviors

- ✅ **Read-Only Operations:** Only read existing code to understand context
- ✅ **Validate Secrets:** If user mentions credentials, warn about security
- ✅ **Explicit Confirmation:** State when requirements compilation is complete
- ✅ **Ask Before Proceeding:** Do NOT auto-advance to implementation without user approval

### Security Considerations

**If user requirements involve:**
- Authentication/authorization → Include security acceptance criteria (e.g., "Passwords hashed with bcrypt")
- User input → Include validation criteria (e.g., "Sanitize all inputs to prevent XSS")
- External APIs → Include credential handling in constraints (e.g., "API keys in .env, never committed")
- File operations → Include path validation (e.g., "Prevent directory traversal")

**Template for security-critical features:**
```markdown
## Security Requirements
- [ ] Input validation implemented (specify method)
- [ ] Secrets stored in environment variables
- [ ] No sensitive data in logs
- [ ] [Framework]-specific best practices followed
- [ ] OWASP Top 10 reviewed and mitigated
```

---

## Output Contract

### Deliverable Format

**Primary Output:**
- Populated PROMPT_BRIEF document (as markdown code block or new file if requested)
- Clearly labeled sections matching template

**Metadata to Include:**
- Complexity assessment (Simple/Medium/Complex)
- Number of questions asked (X/3 budget used)
- Recommended next step (load task-decomposer, enter plan mode, or direct implementation)

### User Handoff

After compiling requirements, output:

```
## Requirements Compilation Complete

**Complexity:** [Simple/Medium/Complex]
**Clarifications Used:** [X/3 questions]

[PROMPT_BRIEF document here]

**Recommended Next Step:**
- [ ] Review requirements above
- [ ] If approved → [load task-decomposer / enter plan mode / begin implementation]
- [ ] If changes needed → specify which section

Do you approve these requirements?
```

**Do NOT proceed to next phase until user explicitly approves.**

---

## Definition of Done

**Requirements compilation is complete when:**

- [ ] All template sections populated (or marked N/A with reason)
- [ ] At least 3 specific, testable acceptance criteria defined
- [ ] Ambiguities resolved within question budget (≤3)
- [ ] Security implications identified if applicable
- [ ] Out of Scope section prevents feature creep
- [ ] User can hand this document to another developer and they'd know what to build
- [ ] No implementation details included (pure requirements)

**NOT Done If:**
- Acceptance criteria vague (e.g., "make it work")
- Missing critical info (e.g., auth feature but no mention of user storage)
- Security-critical feature without security requirements
- User hasn't confirmed requirements are correct

---

## Self-Check

**Before marking complete, verify:**

```
1. COMPLETENESS
   [ ] Purpose answers "what" and "why"?
   [ ] Acceptance criteria testable? (not "improve UX")
   [ ] Constraints capture real limits? (not generic placeholders)
   [ ] Out of Scope explicitly stated?

2. CLARITY
   [ ] Can another developer implement from this doc alone?
   [ ] No ambiguous terms? (e.g., "fast", "secure", "user-friendly" without definition)
   [ ] Edge cases identified in AC?

3. SECURITY
   [ ] Auth/input handling features have security AC?
   [ ] No hardcoded credentials in examples?
   [ ] Warned user about sensitive data handling if relevant?

4. PROCESS
   [ ] Used ≤3 questions?
   [ ] Read existing code if context needed?
   [ ] Did NOT implement anything?
   [ ] Stated recommended next step clearly?

5. EFFICIENCY
   [ ] Used appropriate template (full vs simplified)?
   [ ] Avoided redundant questions (info already provided)?
   [ ] No unnecessary web searches or tool calls?
```

**Action:** If any check fails, revise requirements document before handoff.

---

## Anti-Patterns

### Common Mistakes to Avoid

❌ **Over-Engineering Requirements:**
- Adding acceptance criteria for hypothetical features
- Asking about distant future changes
- Defining metrics for simple bug fixes

❌ **Under-Specifying:**
- "Add auth" → Which method? Where stored? Password rules?
- "Make it fast" → Baseline? Target? Measurement method?

❌ **Mixing Concerns:**
- Including implementation details in requirements (e.g., "Use Redis for caching")
- Solution: Capture in Constraints ("Must use existing Redis instance") not AC

❌ **Breaking Question Budget:**
- Asking 5+ questions for a simple feature
- Solution: Make educated assumptions, document in Assumptions section

❌ **Auto-Advancing:**
- Compiling requirements then immediately implementing
- Solution: STOP after compilation, get user approval

---

## Examples

### Example 1: Simple Feature

**User Input:**
```
Add a logout button to the dashboard
```

**Output:**
```markdown
# Logout Button

## Purpose
Allow authenticated users to terminate their session from the dashboard.

## Acceptance Criteria
- [ ] Logout button visible on dashboard header
- [ ] Clicking button clears session/token
- [ ] User redirected to login page after logout
- [ ] Button styled consistently with existing dashboard buttons

## Constraints
- Must use existing auth library (check codebase for current implementation)
- No breaking changes to current session management

## Out of Scope
- Logout confirmation dialog (can add later if needed)
- "Logout from all devices" functionality
```

**Questions Used:** 0/3 (clear requirements)

---

### Example 2: Medium Feature (with clarification)

**User Input:**
```
Add user authentication
```

**Questions Asked (via AskUserQuestion):**
1. Which authentication method? → JWT selected
2. Where to store user data? → PostgreSQL selected

**Output:**
```markdown
# User Authentication System

## Purpose
Enable secure user login/logout functionality using JWT tokens with PostgreSQL user storage.

## Acceptance Criteria
- [ ] Users can register with email + password
- [ ] Passwords hashed with bcrypt (min cost 10)
- [ ] JWT tokens issued on successful login (24h expiry)
- [ ] Protected routes verify JWT before access
- [ ] Tokens stored in httpOnly cookies (not localStorage)
- [ ] Login failures rate-limited (5 attempts/15min)

## Constraints
- **Technical:** Node.js 18+, PostgreSQL 14+
- **Security:** Follow OWASP auth guidelines
- **Performance:** Login response < 500ms

## Assumptions
- Email service already configured for verification (not part of this task)
- HTTPS enabled in production

## Out of Scope
- Social login (Google, GitHub)
- Password reset flow
- Two-factor authentication

## Dependencies
- `bcrypt` library
- `jsonwebtoken` library
- Existing PostgreSQL connection

## Security Requirements
- [ ] Passwords min 8 chars, never logged
- [ ] SQL injection prevention (parameterized queries)
- [ ] No JWT secret in code (environment variable)
- [ ] Tokens invalidated on logout
```

**Questions Used:** 2/3

---

### Example 3: Complex Feature (budget exhausted)

**User Input:**
```
Improve the app's performance
```

**Questions Asked:**
1. Which part is slow? → API response times selected
2. Target improvement? → < 200ms selected
3. Acceptable tradeoffs? → Can add caching selected

**Output:**
```markdown
# API Performance Optimization

## Purpose
Reduce API endpoint response times to under 200ms (currently ~800ms) through caching and query optimization.

## Scope
- Focus on `/api/users` and `/api/products` endpoints (highest traffic)
- Implement response caching layer
- Optimize database queries

## Acceptance Criteria
- [ ] `/api/users` response < 200ms (95th percentile)
- [ ] `/api/products` response < 200ms (95th percentile)
- [ ] Cache hit rate > 70%
- [ ] No functional regressions (all existing tests pass)
- [ ] Cache invalidation on data mutations

## Constraints
- **Performance:** Target is 200ms, not lower (diminishing returns)
- **Resources:** Use existing Redis instance (no new services)
- **Compatibility:** No breaking changes to API contracts

## Assumptions
- Database server performance is adequate (not a DB hardware issue)
- Traffic patterns allow effective caching (not all unique requests)

## Out of Scope
- Frontend performance (separate effort)
- Other API endpoints (only users/products)
- Database schema changes
- Load balancing / horizontal scaling

## Dependencies
- Existing Redis instance
- Access to production metrics (for baseline)

## Success Metrics
- 95th percentile response time < 200ms
- Cache hit rate measured via Redis stats
- Compare before/after using production traffic replay
```

**Questions Used:** 3/3 (complex scope required clarification)

---

## Meta

- **Skill Version:** 1.0.0
- **Last Updated:** 2026-02-01
- **Trigger Pattern:** Raw/vague user input → structured PROMPT_BRIEF
- **Average Load Duration:** 5-10 minutes (including user Q&A)
- **Typical Output Size:** 30-100 lines (varies by complexity)

**Integration:**
- **Before:** User provides vague idea
- **After:** Load task-decomposer.md (if approved) OR enter plan mode

---

**End of requirements-compiler.md** • Load on-demand only when raw requirements need structuring
