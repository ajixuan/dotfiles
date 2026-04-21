#!/bin/bash
# Block destructive commands: rm -rf, kubectl delete, az delete
COMMAND=$(jq -r '.tool_input.command')

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

echo "$COMMAND" | grep -qE '\brm\b'             && deny "rm is blocked. Instead, rename the file/directory by appending a .DELETE suffix (e.g., mv foo foo.DELETE)"
echo "$COMMAND" | grep -qE 'kubectl\s+delete'  && deny "kubectl delete blocked by hook"
echo "$COMMAND" | grep -qE 'az\s+\S+\s+delete' && deny "az delete blocked by hook"

exit 0  # allow the command
