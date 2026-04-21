INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

[[ "$TOOL" != "Bash" ]] && exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

TRUSTED_PATTERNS=(
  "python3 -c"
  "node -e"
  "npm run"
  "npx "
)

for pattern in "${TRUSTED_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qF "$pattern"; then
    jq -n '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"trusted dev pattern auto-approved"}}'
    exit 0
  fi
done

exit 0
