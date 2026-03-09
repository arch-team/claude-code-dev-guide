#!/bin/bash
# Hook: PreToolUse - 检查写入安全性
# 三重保险第 1 层（确定性）：exit 2 阻断危险写入 [IR-4]

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 阻止写入敏感文件
if [[ "$FILE_PATH" == *".env"* ]] || [[ "$FILE_PATH" == *"credentials"* ]]; then
  echo "BLOCKED: Writing to sensitive file is not allowed: $FILE_PATH" >&2
  exit 2
fi

# 阻止写入 .claude-plugin/ 内的非 manifest 文件 [IR-1]
if [[ "$FILE_PATH" == *".claude-plugin/"* ]]; then
  BASENAME=$(basename "$FILE_PATH")
  if [[ "$BASENAME" != "plugin.json" ]] && [[ "$BASENAME" != "marketplace.json" ]]; then
    echo "BLOCKED: Only plugin.json and marketplace.json allowed in .claude-plugin/ [IR-1]" >&2
    exit 2
  fi
fi

exit 0
