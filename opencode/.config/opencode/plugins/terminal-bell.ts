import type { Plugin } from "@opencode-ai/plugin";

const BELL = "\x07";

export const TerminalBellPlugin: Plugin = async () => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle" || event.type === "permission.asked") {
        process.stdout.write(BELL);
      }
    },
  };
};
