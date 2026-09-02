import type { Plugin } from "@opencode-ai/plugin";

import {
  isMainCheckout,
  blockedForBash,
  blockedForEditTool,
} from "../lib/worktree-guard.ts";

export const WorktreeGuardPlugin: Plugin = async ({ directory }) => {
  if (!isMainCheckout(directory)) return {};

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash" && typeof output.args?.command === "string") {
        const result = blockedForBash(output.args.command);
        if (result.protected) throw new Error(result.reason);
      }
      if (input.tool === "edit" || input.tool === "write") {
        const result = blockedForEditTool(output.args);
        if (result.protected) throw new Error(result.reason);
      }
    },
  };
};
