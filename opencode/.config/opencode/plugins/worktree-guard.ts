import type { Plugin } from "@opencode-ai/plugin";

import {
  isMainCheckout,
  canBashCommandMutate,
  isFileInMainCheckout,
} from "../lib/worktree-guard.ts";

export const WorktreeGuardPlugin: Plugin = async ({ directory }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash" && typeof output.args?.command === "string") {
        // Shell text is too free-form to extract the touched paths, so gate on the session cwd instead.
        if (isMainCheckout(directory)) {
          const result = canBashCommandMutate(output.args.command);
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
