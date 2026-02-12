#!/bin/bash
# TeammateIdle Hook - Prevents teammates from going idle with incomplete tasks
#
# Exit codes:
#   0 = Allow idle (teammate can stop)
#   2 = Reject idle (send stderr as feedback to keep teammate working)
#
# Input (via stdin): JSON with teammate_name, team_name
# Environment: TEAMMATE_NAME, TEAM_NAME (if available)

set -euo pipefail

TEAM_NAME="${TEAM_NAME:-}"
TEAMMATE_NAME="${TEAMMATE_NAME:-}"

# Read stdin for context if available
if [ -t 0 ]; then
  INPUT=""
else
  INPUT=$(cat 2>/dev/null || echo "")
fi

# Extract team_name from input if not in env
if [ -z "$TEAM_NAME" ] && [ -n "$INPUT" ]; then
  TEAM_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('team_name',''))" 2>/dev/null || echo "")
fi

if [ -z "$TEAM_NAME" ]; then
  # No team context - allow idle
  exit 0
fi

TASK_DIR="$HOME/.claude/tasks/$TEAM_NAME"

if [ ! -d "$TASK_DIR" ]; then
  exit 0
fi

# Check for tasks still in_progress assigned to this teammate
IN_PROGRESS=0
for task_file in "$TASK_DIR"/*.json; do
  [ -f "$task_file" ] || continue
  status=$(python3 -c "import json; d=json.load(open('$task_file')); print(d.get('status',''))" 2>/dev/null || echo "")
  owner=$(python3 -c "import json; d=json.load(open('$task_file')); print(d.get('owner',''))" 2>/dev/null || echo "")

  if [ "$status" = "in_progress" ]; then
    if [ -z "$TEAMMATE_NAME" ] || [ "$owner" = "$TEAMMATE_NAME" ]; then
      IN_PROGRESS=$((IN_PROGRESS + 1))
    fi
  fi
done

if [ "$IN_PROGRESS" -gt 0 ]; then
  echo "You have $IN_PROGRESS task(s) still in_progress. Complete or update them before going idle. Check TaskList for your assigned tasks." >&2
  exit 2
fi

# Check for unclaimed pending tasks
PENDING=0
for task_file in "$TASK_DIR"/*.json; do
  [ -f "$task_file" ] || continue
  status=$(python3 -c "import json; d=json.load(open('$task_file')); print(d.get('status',''))" 2>/dev/null || echo "")
  owner=$(python3 -c "import json; d=json.load(open('$task_file')); print(d.get('owner',''))" 2>/dev/null || echo "")
  blocked=$(python3 -c "import json; d=json.load(open('$task_file')); print(len(d.get('blockedBy',[])))" 2>/dev/null || echo "0")

  if [ "$status" = "pending" ] && [ -z "$owner" ] && [ "$blocked" = "0" ]; then
    PENDING=$((PENDING + 1))
  fi
done

if [ "$PENDING" -gt 0 ]; then
  echo "There are $PENDING unclaimed pending task(s) available. Check TaskList and claim one before going idle." >&2
  exit 2
fi

# All tasks done or blocked - allow idle
exit 0
