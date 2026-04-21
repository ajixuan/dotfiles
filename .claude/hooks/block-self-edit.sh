#!/bin/bash
# Block Claude from editing hooks or settings files
# v2: also blocks chmod/chattr and resolves globs/variables before checking

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

PROTECTED_PATTERN='\.claude/(hooks|settings)'

# Check file_path for Edit/Write tools
if [ -n "$FILE_PATH" ]; then
  echo "$FILE_PATH" | grep -qE "$PROTECTED_PATTERN" && deny "Editing hooks and settings files is blocked."
fi

# For Bash commands: expand the command to resolve globs/variables, then check both raw and expanded forms
if [ -n "$COMMAND" ]; then
  # Check the raw command string
  echo "$COMMAND" | grep -qE "$PROTECTED_PATTERN" && deny "Modifying hooks and settings files via shell is blocked."

  # Expand globs and variables to catch bypasses like .claude/hook?/ or $D/hooks/
  EXPANDED=$(bash -c "echo $COMMAND" 2>/dev/null || echo "")
  echo "$EXPANDED" | grep -qE "$PROTECTED_PATTERN" && deny "Modifying hooks and settings files via shell is blocked (detected after expansion)."
fi

exit 0
