import type { Plugin } from "@opencode-ai/plugin";

import {
  isMainCheckout,
  bashCommandCouldMutate,
  isFileInMainCheckout,
} from "../lib/worktree-guard.ts";

export const WorktreeGuardPlugin: Plugin = async ({ directory }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash" && typeof output.args?.command === "string") {
        // Bash mutation paths are heuristic, so gate on the session cwd only.
        if (isMainCheckout(directory)) {
          const result = bashCommandCouldMutate(output.args.command);
          if (result.protected) throw new Error(result.reason);
        }
        return;
      }
      if (input.tool === "edit" || input.tool === "write") {
        const result = isFileInMainCheckout(output.args?.filePath);
        if (result.protected) throw new Error(result.reason);
      }
    },
  };
};
