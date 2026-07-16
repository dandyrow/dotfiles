import type { Plugin } from "@opencode-ai/plugin"

import { evaluateBashCommand } from "../lib/nix-native-guard.ts"

export const NixNativeGuardPlugin: Plugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return
      const command = output.args?.command
      if (typeof command !== "string") return
      const result = evaluateBashCommand(command)
      if (result.blocked) throw new Error(result.reason)
    },
  }
}
