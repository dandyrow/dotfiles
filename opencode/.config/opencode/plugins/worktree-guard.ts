import type { Plugin } from "@opencode-ai/plugin";

import {
  isMainCheckout,
  blockedForBash,
  blockedForFileTool,
} from "../lib/worktree-guard.ts";

export const WorktreeGuardPlugin: Plugin = async ({ directory }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash" && typeof output.args?.command === "string") {
        // Bash mutation paths are heuristic, so gate on the session cwd only.
        if (isMainCheckout(directory)) {
          const result = blockedForBash(output.args.command);
          if (result.protected) throw new Error(result.reason);
        }
        return;
      }
      if (input.tool === "edit" || input.tool === "write") {
        // Resolve the target file itself so symlinked stow paths are caught from any cwd.
        const result = blockedForFileTool(output.args?.filePath);
        if (result.protected) throw new Error(result.reason);
      }
    },
  };
};
