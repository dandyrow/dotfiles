import path from "node:path";
import os from "node:os";
import { realpathSync } from "node:fs";

export type WorktreeGuardResult = {
  protected: boolean;
  reason?: string;
};

const SAFE: WorktreeGuardResult = { protected: false };

const MAIN_DIR = path.join(os.homedir(), ".dotfiles");
const MAIN_DIR_PREFIX = MAIN_DIR + path.sep;
const WORKTREES_PREFIX = path.join(MAIN_DIR, ".worktrees", path.sep);

export function isMainCheckout(dir: string): boolean {
  if (!dir) return false;
  const resolved = path.resolve(dir);
  if (resolved === MAIN_DIR) return true;
  // Exclude worktrees — that's where edits belong.
  return (
    resolved.startsWith(MAIN_DIR_PREFIX) &&
    !resolved.startsWith(WORKTREES_PREFIX)
  );
}

const MESSAGE = `Blocked: this targets the live main dotfiles checkout. Never edit main directly — start a worktree with ./scripts/agent-start.sh <branch> and make changes there.`;

export function canCommandMutate(command: string): WorktreeGuardResult {
  if (typeof command !== "string" || command.length === 0) return SAFE;
  const couldMutate =
    /(?:^|[\s;&|=(])(?:mv|cp|rm|rmdir|mkdir|touch|ln|truncate|dd|tee)\b/s.test(
      command,
    ) ||
    /(?:^|[;&|]\s*)(?:sudo\s+)?(?:cat|echo|printf)\b[^|;&\n]*[>2]>/s.test(
      command,
    ) ||
    /(?:^|[\s;&|])\s*(?:>|>>)\s*\S/.test(command) ||
    /<<-?\s*['"]?\w+['"]?/.test(command);
  return couldMutate
    ? { protected: true, reason: MESSAGE }
    : SAFE;
}

function resolveTarget(targetPath: string): string {
  try {
    return realpathSync(targetPath);
  } catch {
    // New file: symlink-resolve the parent dir, keep the basename.
    try {
      return path.join(realpathSync(path.dirname(targetPath)), path.basename(targetPath));
    } catch {
      return targetPath;
    }
  }
}

export function isFileInMainCheckout(filePath: string): WorktreeGuardResult {
  if (typeof filePath !== "string" || filePath.length === 0) return SAFE;
  return isMainCheckout(resolveTarget(filePath))
    ? { protected: true, reason: MESSAGE }
    : SAFE;
}
