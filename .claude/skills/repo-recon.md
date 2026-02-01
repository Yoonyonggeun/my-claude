# Skill: Repository Reconnaissance

## Purpose

Safely explore unknown codebases to map architecture, identify build systems, discover scripts, and understand project structure without making any modifications.

## Triggers

**Load this skill when:**
- User says "analyze this repository" or "what's the structure of this codebase?"
- Starting work on unfamiliar repository
- Tech stack, build system, or project architecture is unknown
- Need to locate scripts, commands, or entry points
- User asks "how does this project work?" or "what are the available commands?"

**DO NOT load when:**
- User asks to implement/modify specific feature (use regular workflow)
- Searching for specific function/class (use Grep/Glob directly)
- Codebase already familiar from conversation context
- User provides explicit file paths to work with

## Safe Recon Commands

**ALLOWED (Read-only operations):**
```bash
# Directory structure
ls -lah
find . -type f -name "*.json" -o -name "*.yml" -o -name "*.yaml"
tree -L 3 -I 'node_modules|.git|dist|build'

# Package managers & dependencies
cat package.json pyproject.toml Cargo.toml go.mod pom.xml build.gradle

# Build & scripts
cat Makefile Dockerfile docker-compose.yml .github/workflows/*.yml
cat scripts/* bin/*

# Project metadata
cat README.md CONTRIBUTING.md .nvmrc .python-version
git log --oneline -n 10
git branch -a

# Code patterns
rg "func main|def main|class.*Application|@SpringBootApplication" -l
rg "import.*framework|require.*express" -l
```

**PROHIBITED:**
- `rm`, `mv`, `git reset --hard`, `git push --force`
- `npm install`, `pip install`, `cargo build` (without permission)
- Modifying any files
- Running application code or tests (without permission)

## Reconnaissance Procedure

### Phase 1: Project Metadata
```bash
# Identify project type
ls -lah | grep -E "package\.json|requirements\.txt|Cargo\.toml|go\.mod|pom\.xml"

# Check runtime versions
cat .nvmrc .python-version .ruby-version .tool-versions

# Read project description
cat README.md (first 50 lines)
```

### Phase 2: Dependency & Build System
```bash
# Package manifests
cat package.json        # Node.js
cat pyproject.toml      # Python
cat requirements.txt    # Python (legacy)
cat Cargo.toml          # Rust
cat go.mod              # Go
cat pom.xml             # Java/Maven
cat build.gradle        # Java/Gradle

# Scripts & tasks
cat Makefile
cat package.json | jq '.scripts'  # Node.js scripts
cat Justfile
```

### Phase 3: Architecture Mapping
```bash
# Directory structure (3 levels deep, exclude common build artifacts)
find . -maxdepth 3 -type d ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" ! -path "*/build/*"

# Entry points
rg "func main|def main|if __name__|class.*App" -l

# Configuration files
find . -maxdepth 2 -name "*.config.js" -o -name "*.config.ts" -o -name "*.yml" -o -name "*.yaml" -o -name ".env.example"
```

### Phase 4: CI/CD & Automation
```bash
# GitHub Actions
cat .github/workflows/*.yml

# Docker
cat Dockerfile docker-compose.yml

# Pre-commit hooks
cat .pre-commit-config.yaml .husky/pre-commit
```

## What to Record

**Output Format:**
```markdown
# Repository Reconnaissance Report

## Project Identity
- **Type:** [Node.js/Python/Rust/Go/Java/etc.]
- **Framework:** [Express/Django/Actix/Gin/Spring/etc. or None]
- **Language Version:** [from .nvmrc, .python-version, etc.]

## Build & Task System
- **Package Manager:** [npm/yarn/pnpm/pip/cargo/etc.]
- **Available Scripts:**
  ```
  npm run build    # Description from package.json
  npm run test     # Description
  npm run dev      # Description
  ```

## Directory Structure
```
src/
  ├── components/
  ├── services/
  └── utils/
tests/
scripts/
docs/
```

## Entry Points
- Main: `src/index.ts:1`
- Server: `src/server.ts:15`

## CI/CD
- GitHub Actions: `.github/workflows/ci.yml` (runs on push to main)
- Docker: `Dockerfile` (Node 18 alpine base)

## Configuration Files
- `.env.example` (12 variables)
- `tsconfig.json` (strict mode enabled)

## Dependencies (High-level)
- Production: [express, postgres, redis]
- Dev: [typescript, jest, eslint]

## Potential Commands
```bash
npm install       # Install dependencies
npm run dev       # Start dev server
npm run test      # Run test suite
npm run build     # Build for production
```

## Safety Notes
- ⚠️ `.env` file present (not committed) - avoid reading
- ⚠️ `dist/` contains build artifacts - ignore
- ✓ No force-push in git history
- ✓ Pre-commit hooks configured (husky + lint-staged)
```

## Safety Notes

**ALWAYS:**
- Use read-only commands only
- Check for `.env`, `credentials.json` before reading (use `.env.example` instead)
- Avoid triggering builds/installs during reconnaissance
- Use `head -n 50` for large files
- Respect `.gitignore` patterns

**NEVER:**
- Execute application code without permission
- Install dependencies without asking
- Modify any files (this is recon only)
- Run `rm`, `mv`, or destructive git commands
- Read actual secrets files (`.env`, `credentials.json`, etc.)

## Output Contract

**Deliverable:**
- Structured markdown report (see "What to Record" format)
- Include file paths with line numbers for entry points
- Highlight discovered scripts/commands user can run
- Note any safety concerns (exposed secrets, missing .gitignore entries)
- Maximum report length: 150 lines

**Do NOT:**
- Execute builds or tests (only report their existence)
- Make recommendations for code changes (recon is descriptive only)
- Load other skills during reconnaissance
- Include full file contents (use excerpts or summaries)

## Definition of Done

- [ ] Project type and tech stack identified
- [ ] Build system and available scripts documented
- [ ] Directory structure mapped (at least 2 levels deep)
- [ ] Entry points located with file:line references
- [ ] CI/CD configuration summarized (if present)
- [ ] No files modified during reconnaissance
- [ ] No secrets exposed in report
- [ ] User can run discovered commands based on report

## Self-check

**Before completing reconnaissance:**

```
1. SAFETY
   [ ] Used only read-only commands?
   [ ] Avoided reading .env, credentials.json, or other secret files?
   [ ] No package installations triggered?
   [ ] No files modified (git status unchanged)?

2. COMPLETENESS
   [ ] Project type identified?
   [ ] Build system documented?
   [ ] At least 3 runnable commands discovered?
   [ ] Entry points located with file:line refs?

3. TOKEN ECONOMY
   [ ] Used Glob/Grep for file searches (not ls loops)?
   [ ] Parallel tool calls for independent reads?
   [ ] Report ≤ 150 lines?
   [ ] Avoided redundant file reads?

4. ACTIONABILITY
   [ ] User can run project based on report?
   [ ] Scripts/commands clearly documented?
   [ ] Any blockers noted (missing dependencies, etc.)?
   [ ] Report follows "What to Record" format?
```

**If ANY check fails:** Fix issue before delivering report.

---

**Skill Version:** 1.0.0
**Token Budget:** ~800 tokens (loaded on-demand only)
**Maintenance:** Update when new package managers/build systems emerge
