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
  // Exclude worktrees; edits belong there.
  return (
    resolved.startsWith(MAIN_DIR_PREFIX) &&
    !resolved.startsWith(WORKTREES_PREFIX)
  );
}

const MESSAGE = `Blocked: this targets the live main dotfiles checkout. Never edit main directly — start a worktree with ./scripts/agent-start.sh <branch> and make changes there.`;

/** Extract probable file targets from a shell command string. */
function extractTargets(command: string): string[] {
  const targets: string[] = [];

  // mv, cp, rm, rmdir, mkdir, touch, ln, truncate, dd — args after flags are targets.
  for (const cmd of ["mv", "cp", "rm", "rmdir", "mkdir", "touch", "ln", "truncate", "dd"]) {
    const re = new RegExp(`(?:^|[\\s;&|=(])${cmd}\\b(.*)`, "s");
    const m = command.match(re);
    if (m) {
      for (const arg of m[1].split(/\s+/)) {
        if (arg && !arg.startsWith("-")) targets.push(arg);
      }
    }
  }

  // tee — last arg is the output file.
  const teeMatch = command.match(/(?:^|[\s;&|=(])\btee\b(.*)/s);
  if (teeMatch) {
    const args = teeMatch[1].split(/\s+/).filter(Boolean);
    if (args.length && !args[args.length - 1].startsWith("-")) {
      targets.push(args[args.length - 1]);
    }
  }

  // cat/echo/printf with > or >> — extract target after the redirect.
  const redirectMatch = command.match(
    /(?:^|[;&|]\s*)(?:sudo\s+)?(?:cat|echo|printf)\b[^|;&\n]*[>2]>\s*(\S+)/,
  );
  if (redirectMatch) targets.push(redirectMatch[1]);

  // Bare > or >> at top level.
  const bareRedirect = command.match(/(?:^|[\s;&|])\s*(?:>|>>)\s*(\S+)/);
  if (bareRedirect) targets.push(bareRedirect[1]);

  // Deduplicate. Skip relative paths — they're ambiguous without CWD context.
  return [...new Set(targets)].filter((t) => path.isAbsolute(t) || t.startsWith("~") || t.startsWith("."));
}

export function canCommandMutate(command: string): WorktreeGuardResult {
  if (typeof command !== "string" || command.length === 0) return SAFE;

  const targets = extractTargets(command);
  for (const target of targets) {
    if (isMainCheckout(resolveTarget(target))) {
      return { protected: true, reason: MESSAGE };
    }
  }
  return SAFE;
}

function resolveTarget(targetPath: string): string {
  const expanded = targetPath.startsWith("~")
    ? path.join(os.homedir(), targetPath.slice(1))
    : targetPath;
  try {
    return realpathSync(expanded);
  } catch {
    // New file: symlink-resolve the parent dir, keep the basename.
    try {
      return path.join(realpathSync(path.dirname(expanded)), path.basename(expanded));
    } catch {
      return path.resolve(expanded);
    }
  }
}

export function isFileInMainCheckout(filePath: string): WorktreeGuardResult {
  if (typeof filePath !== "string" || filePath.length === 0) return SAFE;
  return isMainCheckout(resolveTarget(filePath))
    ? { protected: true, reason: MESSAGE }
    : SAFE;
}
