import { describe, it } from "node:test";
import assert from "node:assert/strict";

import {
  isMainCheckout,
  canCommandMutate,
  isFileInMainCheckout,
} from "../lib/worktree-guard.ts";

const blocked = (cmd: string) =>
  assert.equal(
    canCommandMutate(cmd).protected,
    true,
    `expected BLOCK: ${cmd}`,
  );
const allowed = (cmd: string) =>
  assert.equal(
    canCommandMutate(cmd).protected,
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

describe("canCommandMutate", () => {
  it("blocks commands targeting files in main checkout", () => {
    blocked("rm ~/.dotfiles/foo");
    blocked("mv a ~/.dotfiles/nix/home/default.nix");
    blocked("cp src ~/.dotfiles/config.json");
    blocked("touch ~/.dotfiles/new-file");
    blocked("mkdir -p ~/.dotfiles/new-dir");
    blocked("ln -s a ~/.dotfiles/link");
    blocked("cat > ~/.dotfiles/config.json");
    blocked("echo hi > ~/.dotfiles/out.txt");
    blocked("printf hi >> ~/.dotfiles/out.txt");
    blocked("tee ~/.dotfiles/out.txt");
  });

  it("blocks symlinked paths that resolve into main checkout", () => {
    blocked("rm ~/.config/opencode/plugins/test.ts");
    blocked("touch ~/.config/opencode/new-file.ts");
    blocked("echo hi > ~/.config/opencode/out.txt");
  });

  it("blocks commands with mixed targets when any resolves into main", () => {
    blocked("mv /tmp/safe-file ~/.dotfiles/nix/home/default.nix");
    blocked("cp /tmp/src ~/.config/opencode/config.json");
  });

  it("allows commands targeting files outside the repo", () => {
    allowed("rm /tmp/pr-body.md");
    allowed("mv a /tmp/b");
    allowed("cp src /tmp/dest");
    allowed("touch /tmp/new-file");
    allowed("mkdir -p /tmp/new-dir");
    allowed("echo hi > /tmp/out.txt");
    allowed("printf hi >> /tmp/out.txt");
    allowed("tee /tmp/out.txt");
    allowed("cat > /tmp/file.txt");
  });

  it("allows commands with all targets outside the repo", () => {
    allowed("mv /tmp/a /tmp/b");
    allowed("cp /tmp/src /tmp/dest");
  });

  it("allows read-only commands", () => {
    allowed("git status");
    allowed("git log --oneline");
    allowed("ls -la");
    allowed("cat file");
    allowed("nix flake check");
    allowed("nix build --no-link .#foo");
    allowed("nix eval .#x");
    allowed("find . -name foo");
    allowed("rg something");
  });

  it("allows heredocs inside non-mutating commands", () => {
    allowed(`gh issue create --title "foo" --body "$(cat <<'EOF'
body
EOF
)"`);
    allowed(`echo "$(cat <<'EOF'
hello
EOF
)"`);
    allowed("gh pr create --body \"$(cat <<'EOF'\ntext\nEOF\n)\"");
  });

  it("allows git add and commit", () => {
    allowed("git add file.nix");
    allowed("git commit -m 'message'");
    allowed("git add . && git commit -m 'msg'");
  });

  it("allows nixos-rebuild (no direct file targets)", () => {
    allowed("nixos-rebuild switch --flake .#WSL");
    allowed("nix flake update");
  });
});

describe("isFileInMainCheckout", () => {
  const mainConfig = `${process.env.HOME}/.dotfiles/opencode/.config/opencode/opencode.json`;

  it("blocks an edit to a tracked file in the main clone", () => {
    assert.equal(isFileInMainCheckout(mainConfig).protected, true);
  });

  it("blocks an edit to a repo file via a ~/.config symlink from any cwd", () => {
    assert.equal(
      isFileInMainCheckout(`${process.env.HOME}/.config/opencode/opencode.json`).protected,
      true,
    );
  });

  it("blocks a new file in the main clone", () => {
    assert.equal(
      isFileInMainCheckout(`${process.env.HOME}/.dotfiles/opencode/.config/opencode/new.ts`).protected,
      true,
    );
  });

  it("allows edits inside a worktree", () => {
    assert.equal(
      isFileInMainCheckout(`${process.env.HOME}/.dotfiles/.worktrees/foo/bar.ts`).protected,
      false,
    );
  });

  it("allows edits outside the repo", () => {
    assert.equal(
      isFileInMainCheckout(`${process.env.HOME}/projects/foo/bar.ts`).protected,
      false,
    );
  });
});
