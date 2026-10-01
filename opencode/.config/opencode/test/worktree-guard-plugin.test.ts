import { describe, it } from "node:test";
import assert from "node:assert/strict";

import { WorktreeGuardPlugin } from "../plugins/worktree-guard.ts";

const MAIN = `${process.env.HOME}/.dotfiles`;
const WORKTREE = `${MAIN}/.worktrees/fix/bats-stub-shebang`;

type PluginInput = Parameters<typeof WorktreeGuardPlugin>[0];

const runBash = async (directory: string, args: Record<string, unknown>) => {
  const hooks = await WorktreeGuardPlugin({ directory } as PluginInput);
  await hooks["tool.execute.before"]!(
    { tool: "bash", sessionID: "s", callID: "c" },
    { args },
  );
};

describe("WorktreeGuardPlugin bash hook", () => {
  it("resolves relative targets against the bash workdir", async () => {
    await runBash(MAIN, { command: "rm .github/workflows/bats.yml", workdir: WORKTREE });
  });

  it("resolves a relative workdir against the session directory", async () => {
    await runBash(MAIN, { command: "rm notes.md", workdir: ".worktrees/fix/bats-stub-shebang" });
    await assert.rejects(runBash(MAIN, { command: "rm notes.md", workdir: "nix" }), /Blocked/);
  });

  it("falls back to the session directory without a workdir", async () => {
    await assert.rejects(runBash(MAIN, { command: "rm .github/workflows/bats.yml" }), /Blocked/);
  });
});
