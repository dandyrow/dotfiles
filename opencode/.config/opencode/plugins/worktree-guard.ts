import path from "node:path";
import type { Plugin } from "@opencode-ai/plugin";

import {
  isMainCheckout,
  canCommandMutate,
  isFileInMainCheckout,
} from "../lib/worktree-guard.ts";

export const WorktreeGuardPlugin: Plugin = async ({ directory }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash" && typeof output.args?.command === "string") {
        const workdir = output.args.workdir;
        const cwd = typeof workdir === "string" ? path.resolve(directory, workdir) : directory;
        // Shell parsing is best-effort, so only sessions that can reach main pay for its false positives.
        if (isMainCheckout(directory) || isMainCheckout(cwd)) {
          const result = canCommandMutate(output.args.command, cwd);
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
