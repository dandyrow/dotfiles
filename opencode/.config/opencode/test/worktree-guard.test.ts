import { describe, it } from "node:test";
import assert from "node:assert/strict";

import {
  isMainCheckout,
  canCommandMutate,
  isFileInMainCheckout,
} from "../lib/worktree-guard.ts";

const MAIN = `${process.env.HOME}/.dotfiles`;
const WORKTREE = `${MAIN}/.worktrees/fix/bats-stub-shebang`;

const blocked = (cmd: string, cwd = "/tmp") =>
  assert.equal(
    canCommandMutate(cmd, cwd).protected,
    true,
    `expected BLOCK: ${cmd} (cwd ${cwd})`,
  );
const allowed = (cmd: string, cwd = "/tmp") =>
  assert.equal(
    canCommandMutate(cmd, cwd).protected,
    false,
    `expected ALLOW: ${cmd} (cwd ${cwd})`,
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

  it("attributes only a command's own segment to it in a compound command", () => {
    allowed("rm /tmp/opencode/nope; grep -c isMainCheckout ~/.config/opencode/lib/worktree-guard.ts");
    allowed("mv /tmp/a /tmp/b && cat ~/.dotfiles/README.md");
    allowed("touch /tmp/x || ls ~/.dotfiles");
    allowed("tee /tmp/out.txt | wc -l ~/.dotfiles/README.md");
    allowed("echo hi > /tmp/out.txt; cat ~/.dotfiles/README.md");
    allowed("rm /tmp/x\ngrep foo ~/.dotfiles/README.md");
  });

  it("blocks a mutating command in a later segment of a compound command", () => {
    blocked("ls /tmp && rm ~/.dotfiles/foo");
    blocked("cat /tmp/x | tee ~/.dotfiles/out.txt");
    blocked("ls; echo hi > ~/.dotfiles/out.txt");
  });

  it("allows absolute targets inside a worktree", () => {
    allowed(`rm ${WORKTREE}/.github/workflows/nope.yml`, MAIN);
  });

  it("resolves relative targets against the supplied cwd", () => {
    allowed("rm .github/workflows/bats.yml", WORKTREE);
    blocked("rm .github/workflows/bats.yml", MAIN);
    allowed("rm ./foo", WORKTREE);
    blocked("rm ./foo", MAIN);
    allowed("touch notes.md", WORKTREE);
    blocked("touch notes.md", MAIN);
    blocked("mkdir -p new-dir", `${MAIN}/nix`);
    blocked("rm ../../../flake.nix", WORKTREE);
    allowed("echo hi > out.txt", WORKTREE);
    blocked("echo hi > out.txt", MAIN);
  });

  it("resolves relative targets against a directory changed by an earlier cd", () => {
    allowed("cd .worktrees/fix/x && rm foo", MAIN);
    allowed("cd /tmp; touch notes.md", MAIN);
    allowed("cd -P /tmp && mkdir new-dir", MAIN);
    blocked("cd ~/.dotfiles && rm foo", WORKTREE);
    blocked("cd ../../.. && touch notes.md", WORKTREE);
    blocked("cd && rm .dotfiles/flake.nix");
    blocked("cd /tmp && cd ~/.dotfiles/nix && touch x", MAIN);
  });

  it("allows commands with all targets outside the repo", () => {
    allowed("mv /tmp/a /tmp/b");
    allowed("cp /tmp/src /tmp/dest");
  });

  it("allows read-only commands", () => {
    allowed("git status", MAIN);
    allowed("git log --oneline", MAIN);
    allowed("ls -la", MAIN);
    allowed("cat file", MAIN);
    allowed("nix flake check", MAIN);
    allowed("nix build --no-link .#foo", MAIN);
    allowed("nix eval .#x", MAIN);
    allowed("find . -name foo", MAIN);
    allowed("rg something", MAIN);
    allowed("ls 2>&1 | head", MAIN);
  });

  it("allows heredocs inside non-mutating commands", () => {
    allowed(`gh issue create --title "foo" --body "$(cat <<'EOF'
body
EOF
)"`, MAIN);
    allowed(`echo "$(cat <<'EOF'
hello
EOF
)"`, MAIN);
    allowed("gh pr create --body \"$(cat <<'EOF'\ntext\nEOF\n)\"", MAIN);
  });

  it("ignores shell syntax in heredoc bodies and quoted arguments", () => {
    allowed(`gh issue create --title "guard bug" --body "$(cat <<'EOF'
Repro: rm notes.md; then touch other.md
Fails when count > 5 && mkdir foo
EOF
)"`, MAIN);
    allowed(`cat <<-EOF | wc -l
\trm notes.md > out
\tEOF`, MAIN);
    allowed(`git commit -m "fix: rm stale file when size > 3; touch nothing"`, MAIN);
    allowed(`gh pr create --body 'tee log && mv a b'`, MAIN);
  });

  it("still checks commands that run after a heredoc or inside a substitution", () => {
    blocked(`cat <<'EOF' > /tmp/x
text
EOF
rm notes.md`, MAIN);
    blocked(`cat <<'EOF' > notes.md
text
EOF`, MAIN);
    blocked(`echo "$(rm ~/.dotfiles/foo)"`);
    blocked(`echo "$(touch notes.md)"`, MAIN);
    blocked(`rm "notes file.md"`, MAIN);
  });

  it("checks commands run through a shell, wrapper or find -exec", () => {
    blocked(`sh -c "cd /tmp; rm ~/.dotfiles/flake.nix"`);
    blocked(`bash -c 'touch notes.md'`, MAIN);
    blocked(`bash <<'EOF'
rm ~/.dotfiles/flake.nix
EOF`);
    blocked("sudo -u root rm ~/.dotfiles/flake.nix");
    blocked("timeout 5 rm ~/.dotfiles/flake.nix");
    blocked("nice -n 10 rm ~/.dotfiles/flake.nix");
    blocked("xargs -0 rm ~/.dotfiles/flake.nix");
    blocked("find /tmp -name x -exec rm ~/.dotfiles/flake.nix \\;");
    allowed(`sh -c "rm /tmp/x"`, MAIN);
    allowed("find . -name '*.orig' -exec rm {} +", WORKTREE);
  });

  it("follows pushd and git -C to the directory they target", () => {
    blocked("pushd ~/.dotfiles && rm ./flake.nix", WORKTREE);
    blocked("git -C ~/.dotfiles rm flake.nix", WORKTREE);
    allowed(`git -C ${WORKTREE} rm flake.nix`, MAIN);
  });

  it("checks only the destination of cp and ln", () => {
    allowed("cp README.md /tmp/x", MAIN);
    allowed("cp -r nix /tmp/backup", MAIN);
    allowed("ln -s ~/.dotfiles/flake.nix /tmp/link");
    blocked("cp /tmp/x notes.md", MAIN);
    blocked("cp -t ~/.dotfiles/nix /tmp/a");
    blocked("cp -rt ~/.dotfiles/nix /tmp/a");
    blocked("ln -st ~/.dotfiles/nix /tmp/a");
    blocked("cp --target-directory=nix /tmp/a", MAIN);
    blocked("ln -s /tmp/target", MAIN);
    blocked("mv ~/.dotfiles/flake.nix /tmp/x");
  });

  it("only treats a mutating name in command position as the command", () => {
    allowed("grep -rn rm lib", MAIN);
    allowed("git log --grep touch", MAIN);
    blocked("sudo rm notes.md", MAIN);
    blocked("FOO=1 rm notes.md", MAIN);
    blocked("git rm notes.md", MAIN);
    blocked("git mv a b", MAIN);
  });

  it("does not mistake flag values or fd numbers for targets", () => {
    allowed("rm /tmp/x 2>/dev/null", MAIN);
    allowed("truncate -s 0 /tmp/x", MAIN);
    allowed("mkdir -m 700 /tmp/x", MAIN);
    allowed("touch -d yesterday /tmp/x", MAIN);
    allowed("dd if=README.md of=/tmp/x", MAIN);
    blocked("dd if=/tmp/x of=out.img", MAIN);
  });

  it("allows git add and commit", () => {
    allowed("git add file.nix", MAIN);
    allowed("git commit -m 'message'", MAIN);
    allowed("git add . && git commit -m 'msg'", MAIN);
  });

  it("allows nixos-rebuild (no direct file targets)", () => {
    allowed("nixos-rebuild switch --flake .#WSL", MAIN);
    allowed("nix flake update", MAIN);
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
