#!/bin/bash
# PostToolUse hook: verify integrity of protected files after every tool call
CHECKSUM_FILE="$CLAUDE_PROJECT_DIR/.claude/hooks/.checksums"

if [ -f "$CHECKSUM_FILE" ]; then
  if ! sha256sum --check "$CHECKSUM_FILE" --quiet 2>/dev/null; then
    echo "TAMPERING DETECTED: Hook or settings files have been modified!"
    echo "Run: cd $CLAUDE_PROJECT_DIR && git checkout -- .claude/ to restore."
  fi
fi

exit 0
