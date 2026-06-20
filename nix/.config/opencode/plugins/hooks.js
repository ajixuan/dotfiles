export const ClaudeHooks = async ({ $, directory }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // block-destructive.sh: deny rm, kubectl delete, az delete
      if (input.tool === "bash") {
        const cmd = output.args.command
        if (/\brm\b/.test(cmd)) {
          throw new Error("rm is blocked. Instead, rename the file/directory by appending a .DELETE suffix (e.g., mv foo foo.DELETE)")
        }
        if (/kubectl\s+delete/.test(cmd)) {
          throw new Error("kubectl delete blocked by hook")
        }
        if (/az\s+\S+\s+delete/.test(cmd)) {
          throw new Error("az delete blocked by hook")
        }
      }

      // block-self-edit.sh: block editing hook/config files
      if (input.tool === "edit" || input.tool === "write") {
        const filePath = output.args.filePath
        if (filePath) {
          if (/\.claude\/(hooks|settings)/.test(filePath)) {
            throw new Error("Editing hooks and settings files is blocked.")
          }
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      // review-changes.sh: run prettier after edits
      if (input.tool === "edit" || input.tool === "write") {
        const filePath = output.args.filePath
        if (filePath && /\.(ts|tsx|js|jsx|json|md)$/.test(filePath)) {
          await $`npx prettier --write ${filePath} 2>/dev/null`.nothrow()
        }
      }
    },
  }
}
