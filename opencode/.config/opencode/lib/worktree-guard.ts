import path from "node:path";
import os from "node:os";

export type WorktreeGuardResult = {
  protected: boolean;
  reason?: string;
};

const SAFE: WorktreeGuardResult = { protected: false };

export const MAIN_REPO_DIR_NAME = ".dotfiles";
export const WORKTREES_DIR_NAME = ".worktrees";

const MAIN_DIR = path.join(os.homedir(), MAIN_REPO_DIR_NAME);
const MAIN_DIR_PREFIX = MAIN_DIR + path.sep;
const WORKTREES_PREFIX = path.join(MAIN_DIR, WORKTREES_DIR_NAME, path.sep);

export function isMainCheckout(dir: string): boolean {
  if (!dir) return false;
  const resolved = path.resolve(dir);
  if (resolved === MAIN_DIR) return true;
  // Inside the clone, but only a worktree counts as safe to edit.
  return (
    resolved.startsWith(MAIN_DIR_PREFIX) &&
    !resolved.startsWith(WORKTREES_PREFIX)
  );
}

const MESSAGE = `Blocked: this targets the live main dotfiles checkout. Never edit main directly — start a worktree with ./scripts/agent-start.sh <branch> and make changes there.`;

export function blockedForBash(command: string): WorktreeGuardResult {
  if (typeof command !== "string" || command.length === 0) return SAFE;
  const couldMutate =
    /(?:^|[\s;&|=(])(?:mv|cp|rm|rmdir|mkdir|touch|ln|truncate|dd|tee)\b/s.test(
      command,
    ) ||
    /(?:^|[;&|]\s*)(?:sudo\s+)?(?:cat|echo|printf)\b[^|;&\n]*[>2]>/s.test(
      command,
    ) ||
    /(?:^|[\s;&|])\s*(?:>|>>)\s*\S/.test(command);
  return couldMutate
    ? { protected: true, reason: MESSAGE }
    : SAFE;
}

export function blockedForEditTool(): WorktreeGuardResult {
  return { protected: true, reason: MESSAGE };
}
