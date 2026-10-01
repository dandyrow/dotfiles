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

type Word = { text: string; redirect?: "in" | "out" };
type Segment = Word[];
type Heredoc = { delimiter: string; stripTabs: boolean };

const REDIRECT = /^(?:&>>?|>>|>\||<<<|<>|>|<)/;
const HEREDOC_DELIMITER = /^(['"]?)\\?([^\s'";&|<>()]+)\1/;

// Heredoc bodies are data, so prose in a PR body can't read as a command.
function parseSegments(src: string): Segment[] {
  const segments: Segment[] = [];
  let i = 0;

  const skipHeredocBody = ({ delimiter, stripTabs }: Heredoc) => {
    while (i < src.length) {
      const nl = src.indexOf("\n", i);
      const end = nl === -1 ? src.length : nl;
      const line = src.slice(i, end);
      i = end + 1;
      if ((stripTabs ? line.replace(/^\t+/, "") : line) === delimiter) return;
    }
  };

  const scan = (untilParen: boolean): void => {
    let words: Word[] = [];
    let word = "";
    let inWord = false;
    let depth = 0;
    const heredocs: Heredoc[] = [];

    const endWord = () => {
      if (inWord) words.push({ text: word });
      word = "";
      inWord = false;
    };
    const endSegment = () => {
      endWord();
      if (words.length) segments.push(words);
      words = [];
    };
    // Keep the raw text so `rm "$(x)/y"` still yields a relative, checkable target.
    const substitution = () => {
      const start = i;
      i += 2;
      scan(true);
      return src.slice(start, i);
    };

    while (i < src.length) {
      const c = src[i];
      if (c === "\\") {
        if (src[i + 1] !== "\n") {
          word += src[i + 1] ?? "";
          inWord = true;
        }
        i += 2;
      } else if (c === "'") {
        const end = src.indexOf("'", i + 1);
        const stop = end === -1 ? src.length : end;
        word += src.slice(i + 1, stop);
        inWord = true;
        i = stop + 1;
      } else if (c === '"') {
        i++;
        inWord = true;
        while (i < src.length && src[i] !== '"') {
          if (src[i] === "\\") {
            word += src[i + 1] ?? "";
            i += 2;
          } else if (src.startsWith("$(", i)) {
            word += substitution();
          } else {
            word += src[i++];
          }
        }
        i++;
      } else if (src.startsWith("$(", i)) {
        word += substitution();
        inWord = true;
      } else if (c === "#" && !inWord) {
        while (i < src.length && src[i] !== "\n") i++;
      } else if (c === " " || c === "\t") {
        endWord();
        i++;
      } else if (c === "\n") {
        endSegment();
        i++;
        for (const heredoc of heredocs.splice(0)) skipHeredocBody(heredoc);
      } else if (src.startsWith("<<", i) && !src.startsWith("<<<", i)) {
        endWord();
        i += 2;
        const stripTabs = src[i] === "-";
        if (stripTabs) i++;
        while (src[i] === " " || src[i] === "\t") i++;
        const m = HEREDOC_DELIMITER.exec(src.slice(i));
        if (m) {
          heredocs.push({ delimiter: m[2], stripTabs });
          i += m[0].length;
        }
      } else if (REDIRECT.test(src.slice(i, i + 3))) {
        const op = REDIRECT.exec(src.slice(i, i + 3))![0];
        // A leading fd number belongs to the operator, not the argument list.
        if (/^\d+$/.test(word)) {
          word = "";
          inWord = false;
        } else {
          endWord();
        }
        i += op.length;
        if (src[i] === "&") {
          i++;
          while (/[\d-]/.test(src[i] ?? "")) i++;
        } else {
          words.push({ text: op, redirect: op.includes(">") ? "out" : "in" });
        }
      } else if (c === "(") {
        depth++;
        endSegment();
        i++;
      } else if (c === ")") {
        endSegment();
        i++;
        if (untilParen && depth === 0) return;
        depth--;
      } else if (";&|`".includes(c)) {
        endSegment();
        i++;
      } else {
        word += c;
        inWord = true;
        i++;
      }
    }
    endSegment();
  };

  scan(false);
  return segments;
}

const MUTATORS = new Set(["mv", "cp", "rm", "rmdir", "mkdir", "touch", "ln", "truncate", "tee"]);
const WRAPPERS = new Set(["sudo", "doas", "command", "builtin", "exec", "nohup", "time", "env", "!", "{", "if", "then", "elif", "else", "while", "until", "do"]);
const ASSIGNMENT = /^[A-Za-z_]\w*=/;
const VALUE_FLAGS: Record<string, string[]> = {
  mkdir: ["-m", "--mode"],
  touch: ["-d", "-r", "-t", "--date", "--reference"],
  truncate: ["-s", "-r", "--size", "--reference"],
  mv: ["-S", "--suffix"],
  cp: ["-S", "--suffix"],
  ln: ["-S", "--suffix"],
};

function operands(cmd: string, args: string[]): string[] {
  const valueFlags = VALUE_FLAGS[cmd] ?? [];
  const result: string[] = [];
  for (let k = 0; k < args.length; k++) {
    if (args[k] === "--") return [...result, ...args.slice(k + 1)];
    if (valueFlags.includes(args[k])) k++;
    else if (!args[k].startsWith("-")) result.push(args[k]);
  }
  return result;
}

function destination(cmd: string, args: string[]): string[] {
  const flag = args.findIndex((a) => a === "-t" || a === "--target-directory");
  if (flag !== -1) return args.slice(flag + 1, flag + 2);
  const long = args.find((a) => a.startsWith("--target-directory="));
  if (long) return [long.slice("--target-directory=".length)];
  const ops = operands(cmd, args);
  // `ln TARGET` with no link name creates the link in the cwd.
  if (cmd === "ln" && ops.length === 1) return [path.basename(ops[0])];
  return ops.slice(-1);
}

type SegmentEffect = { targets: string[]; cd?: string };

function segmentEffect(segment: Segment): SegmentEffect {
  const targets: string[] = [];
  const argv: string[] = [];
  for (let k = 0; k < segment.length; k++) {
    const { text, redirect } = segment[k];
    if (!redirect) {
      argv.push(text);
      continue;
    }
    const next = segment[k + 1];
    if (next && !next.redirect) {
      k++;
      if (redirect === "out") targets.push(next.text);
    }
  }

  let n = 0;
  while (n < argv.length && (WRAPPERS.has(argv[n]) || ASSIGNMENT.test(argv[n]) || (n > 0 && argv[n].startsWith("-")))) n++;
  let [cmd, ...args] = argv.slice(n);

  if (cmd === "cd") {
    return { targets, cd: args.find((a) => !a.startsWith("-")) ?? "~" };
  }

  if (cmd === "git") {
    let k = 0;
    while (k < args.length && args[k].startsWith("-")) k += args[k] === "-C" || args[k] === "-c" ? 2 : 1;
    if (args[k] !== "rm" && args[k] !== "mv") return { targets };
    [cmd, ...args] = args.slice(k);
  }

  if (cmd === "dd") {
    targets.push(...args.filter((a) => a.startsWith("of=")).map((a) => a.slice(3)));
  } else if (cmd === "cp" || cmd === "ln") {
    targets.push(...destination(cmd, args));
  } else if (MUTATORS.has(cmd)) {
    targets.push(...operands(cmd, args));
  }
  return { targets };
}

export function canCommandMutate(command: string, cwd: string): WorktreeGuardResult {
  if (typeof command !== "string" || command.length === 0) return SAFE;

  let dir = cwd;
  for (const segment of parseSegments(command)) {
    const { targets, cd } = segmentEffect(segment);
    if (targets.some((target) => isMainCheckout(resolveTarget(target, dir)))) {
      return { protected: true, reason: MESSAGE };
    }
    if (cd !== undefined) dir = resolveTarget(cd, dir);
  }
  return SAFE;
}

function resolveTarget(targetPath: string, cwd: string): string {
  const expanded = path.resolve(
    cwd,
    targetPath.startsWith("~") ? path.join(os.homedir(), targetPath.slice(1)) : targetPath,
  );
  try {
    return realpathSync(expanded);
  } catch {
    // New file: symlink-resolve the parent dir, keep the basename.
    try {
      return path.join(realpathSync(path.dirname(expanded)), path.basename(expanded));
    } catch {
      return expanded;
    }
  }
}

export function isFileInMainCheckout(filePath: string): WorktreeGuardResult {
  if (typeof filePath !== "string" || filePath.length === 0) return SAFE;
  return isMainCheckout(resolveTarget(filePath, process.cwd()))
    ? { protected: true, reason: MESSAGE }
    : SAFE;
}
