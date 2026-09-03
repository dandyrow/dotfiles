import { describe, it } from "node:test";
import assert from "node:assert/strict";

import {
  isMainCheckout,
  blockedForBash,
  blockedForFileTool,
} from "../lib/worktree-guard.ts";

const blocked = (cmd: string) =>
  assert.equal(
    blockedForBash(cmd).protected,
    true,
    `expected BLOCK: ${cmd}`,
  );
const allowed = (cmd: string) =>
  assert.equal(
    blockedForBash(cmd).protected,
    false,
    `expected ALLOW: ${cmd}`,
  );

describe("isMainCheckout", () => {
  it("recognizes the main ~/.dotfiles clone", () => {
    assert.equal(isMainCheckout(`${process.env.HOME}/.dotfiles`), true);
  });

  it("recognizes a subdirectory inside the main clone", () => {
    assert.equal(
      isMainCheckout(`${process.env.HOME}/.dotfiles/nix/home`),
      true,
    );
  });

  it("does not treat a worktree as the main clone", () => {
    assert.equal(
      isMainCheckout(
        `${process.env.HOME}/.dotfiles/.worktrees/refactor/kitty`,
      ),
      false,
    );
  });

  it("does not treat an unrelated directory as the main clone", () => {
    assert.equal(isMainCheckout(`${process.env.HOME}/projects/foo`), false);
  });
});

describe("blockedForBash", () => {
  it("blocks file-mutating commands", () => {
    blocked("mv a b");
    blocked("rm -r kitty/");
    blocked("rmdir old");
    blocked("mkdir -p foo/bar");
    blocked("touch foo");
    blocked("cp a b");
    blocked("ln -s a b");
    blocked("cat > file");
    blocked("cat > current-theme.conf");
    blocked("cat file > out.txt");
    blocked("echo hi > file");
    blocked("printf hi >> file");
    blocked("tee out.txt");
    blocked("sudo rm /nix/store/foo");
    blocked("foo && mv a b");
    blocked("cd /tmp && rm x");
  });

  it("allows read-only and build commands", () => {
    allowed("git status");
    allowed("git log --oneline");
    allowed("git ls-files");
    allowed("ls -la");
    allowed("cat file");
    allowed("nix flake check");
    allowed("nix build --no-link .#foo");
    allowed("nix eval .#x");
    allowed("find . -name foo");
    allowed("rg something");
  });
});

describe("blockedForFileTool", () => {
  const mainConfig = `${process.env.HOME}/.dotfiles/opencode/.config/opencode/opencode.json`;

  it("blocks an edit to a tracked file in the main clone", () => {
    assert.equal(blockedForFileTool(mainConfig).protected, true);
  });

  it("blocks an edit to a repo file via a ~/.config symlink from any cwd", () => {
    assert.equal(
      blockedForFileTool(`${process.env.HOME}/.config/opencode/opencode.json`).protected,
      true,
    );
  });

  it("blocks a new file in the main clone", () => {
    assert.equal(
      blockedForFileTool(`${process.env.HOME}/.dotfiles/opencode/.config/opencode/new.ts`).protected,
      true,
    );
  });

  it("allows edits inside a worktree", () => {
    assert.equal(
      blockedForFileTool(`${process.env.HOME}/.dotfiles/.worktrees/foo/bar.ts`).protected,
      false,
    );
  });

  it("allows edits outside the repo", () => {
    assert.equal(
      blockedForFileTool(`${process.env.HOME}/projects/foo/bar.ts`).protected,
      false,
    );
  });
});
