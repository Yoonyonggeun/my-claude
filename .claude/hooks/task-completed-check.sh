#!/bin/bash
# TaskCompleted Hook - Validates task quality before allowing completion
#
# Exit codes:
#   0 = Allow completion
#   2 = Reject completion (send stderr as feedback)
#
# Input (via stdin): JSON with task_id, task_subject, task_description,
#                    teammate_name, team_name

set -euo pipefail

INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat 2>/dev/null || echo "")
fi

TASK_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task_id',''))" 2>/dev/null || echo "")
TASK_SUBJECT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task_subject',''))" 2>/dev/null || echo "")
TEAM_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('team_name',''))" 2>/dev/null || echo "")

# If no task context, allow (non-team scenario)
if [ -z "$TASK_ID" ]; then
  exit 0
fi

ERRORS=""

# Check 1: Verify no secrets in git staging area
SECRETS_PATTERN='(password|secret|api_key|apikey|token|credential|private_key)[\s]*[=:]'
if git diff --cached --name-only 2>/dev/null | head -20 | while read -r file; do
  [ -f "$file" ] || continue
  if grep -iEq "$SECRETS_PATTERN" "$file" 2>/dev/null; then
    echo "found"
    break
  fi
done | grep -q "found"; then
  ERRORS="${ERRORS}SECURITY: Possible secrets detected in staged files. Run 'git diff --cached' to review.\n"
fi

# Check 2: Verify no .env or credentials files staged
SENSITIVE_FILES=$(git diff --cached --name-only 2>/dev/null | grep -iE '(\.env|credentials|\.pem|\.key|secret)' || true)
if [ -n "$SENSITIVE_FILES" ]; then
  ERRORS="${ERRORS}SECURITY: Sensitive files staged for commit: $SENSITIVE_FILES\n"
fi

# Check 3: If task mentions 'test', check that tests exist or were run
if echo "$TASK_SUBJECT" | grep -iqE '(test|spec|verify)'; then
  # Just a reminder - can't enforce test execution from a hook
  : # Allow - testing enforcement is advisory
fi

if [ -n "$ERRORS" ]; then
  echo -e "Task #$TASK_ID cannot be completed:\n$ERRORS\nFix these issues before marking the task as completed." >&2
  exit 2
fi

exit 0
