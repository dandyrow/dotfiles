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
type Heredoc = { delimiter: string; stripTabs: boolean; script: boolean };

const REDIRECT = /^(?:&>>?|>>|>\||<<<|<>|>|<)/;
const HEREDOC_DELIMITER = /^(['"]?)\\?([^\s'";&|<>()]+)\1/;
const SHELLS = new Set(["sh", "bash", "zsh", "dash", "ksh"]);

// Heredoc bodies are data unless a shell reads them, so prose in a PR body can't read as a command.
function parseSegments(src: string): Segment[] {
  const segments: Segment[] = [];
  let i = 0;

  const readHeredocBody = ({ delimiter, stripTabs, script }: Heredoc) => {
    const start = i;
    while (i < src.length) {
      const nl = src.indexOf("\n", i);
      const end = nl === -1 ? src.length : nl;
      const line = src.slice(i, end);
      const lineStart = i;
      i = end + 1;
      if ((stripTabs ? line.replace(/^\t+/, "") : line) === delimiter) {
        if (script) segments.push(...parseSegments(src.slice(start, lineStart)));
        return;
      }
    }
    if (script) segments.push(...parseSegments(src.slice(start)));
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
      const redirect = REDIRECT.exec(src.slice(i, i + 3))?.[0];
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
        for (const heredoc of heredocs.splice(0)) readHeredocBody(heredoc);
      } else if (src.startsWith("<<", i) && !src.startsWith("<<<", i)) {
        endWord();
        i += 2;
        const stripTabs = src[i] === "-";
        if (stripTabs) i++;
        while (src[i] === " " || src[i] === "\t") i++;
        const m = HEREDOC_DELIMITER.exec(src.slice(i));
        if (m) {
          const script = words.some((w) => !w.redirect && SHELLS.has(path.basename(w.text)));
          heredocs.push({ delimiter: m[2], stripTabs, script });
          i += m[0].length;
        }
      } else if (redirect) {
        // A leading fd number belongs to the operator, not the argument list.
        if (/^\d+$/.test(word)) {
          word = "";
          inWord = false;
        } else {
          endWord();
        }
        i += redirect.length;
        if (src[i] === "&") {
          i++;
          while (/[\d-]/.test(src[i] ?? "")) i++;
        } else {
          words.push({ text: redirect, redirect: redirect.includes(">") ? "out" : "in" });
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
const SHELL_KEYWORDS = new Set(["!", "{", "if", "then", "elif", "else", "while", "until", "do", "time"]);
// Listing the value-taking flags stops `sudo -u root rm` reading `root` as the command.
const PREFIX_VALUE_FLAGS: Record<string, string[]> = {
  sudo: ["-u", "-g", "-C", "-D", "-h", "-p", "-r", "-t", "-U"],
  doas: ["-u", "-C"],
  env: ["-u", "-C", "-S"],
  nice: ["-n"],
  ionice: ["-c", "-n", "-p"],
  timeout: ["-s", "-k"],
  xargs: ["-a", "-d", "-E", "-I", "-L", "-n", "-P", "-s"],
  command: [],
  builtin: [],
  exec: [],
  nohup: [],
};
const ASSIGNMENT = /^[A-Za-z_]\w*=/;
const VALUE_FLAGS: Record<string, string[]> = {
  mkdir: ["-m", "--mode"],
  touch: ["-d", "-r", "-t", "--date", "--reference"],
  truncate: ["-s", "-r", "--size", "--reference"],
  mv: ["-S", "--suffix"],
  cp: ["-S", "--suffix"],
  ln: ["-S", "--suffix"],
};
const FIND_EXEC = new Set(["-exec", "-execdir", "-ok", "-okdir"]);

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
  for (let k = 0; k < args.length; k++) {
    if (args[k] === "--target-directory") return args.slice(k + 1, k + 2);
    if (args[k].startsWith("--target-directory=")) return [args[k].slice("--target-directory=".length)];
    const cluster = /^-[A-Za-z]*t(.*)$/.exec(args[k]);
    if (cluster) return cluster[1] ? [cluster[1]] : args.slice(k + 1, k + 2);
  }
  const ops = operands(cmd, args);
  // `ln TARGET` with no link name creates the link in the cwd.
  if (cmd === "ln" && ops.length === 1) return [path.basename(ops[0])];
  return ops.slice(-1);
}

function commandStart(argv: string[]): number {
  let n = 0;
  while (n < argv.length) {
    const word = argv[n];
    if (SHELL_KEYWORDS.has(word) || ASSIGNMENT.test(word)) {
      n++;
      continue;
    }
    const valueFlags = PREFIX_VALUE_FLAGS[word];
    if (!valueFlags) return n;
    n++;
    while (n < argv.length && argv[n].startsWith("-")) n += valueFlags.includes(argv[n]) ? 2 : 1;
    if (word === "timeout") n++;
  }
  return n;
}

type CommandEffect = { targets: string[]; cd?: string; script?: string };

function commandEffect(argv: string[]): CommandEffect {
  const [name = "", ...rest] = argv.slice(commandStart(argv));
  let cmd = path.basename(name);
  let args = rest;

  if (cmd === "cd" || cmd === "pushd") {
    const dest = args.find((a) => a === "-" || !a.startsWith("-"));
    // `cd -` goes somewhere this parser can't know, so keep the current directory.
    if (dest === "-") return { targets: [] };
    return { targets: [], cd: dest ?? (cmd === "cd" ? "~" : undefined) };
  }

  if (SHELLS.has(cmd)) {
    const flag = args.findIndex((a) => /^-[a-z]*c[a-z]*$/.test(a));
    return { targets: [], script: flag === -1 ? undefined : args[flag + 1] };
  }

  if (cmd === "find") {
    const exec = args.findIndex((a) => FIND_EXEC.has(a));
    if (exec === -1) return { targets: [] };
    const end = args.findIndex((a, k) => k > exec && (a === ";" || a === "+"));
    const inner = commandEffect(args.slice(exec + 1, end === -1 ? undefined : end));
    const expression = args.findIndex((a) => /^[-(!]/.test(a));
    const roots = args.slice(0, expression === -1 ? args.length : expression);
    return {
      targets: inner.targets.flatMap((t) => (t.includes("{}") ? (roots.length ? roots : ["."]) : [t])),
    };
  }

  let base: string | undefined;
  if (cmd === "git") {
    let k = 0;
    while (k < args.length && args[k].startsWith("-")) {
      if (args[k] === "-C") base = args[k + 1];
      k += args[k] === "-C" || args[k] === "-c" ? 2 : 1;
    }
    if (args[k] !== "rm" && args[k] !== "mv") return { targets: [] };
    [cmd, ...args] = args.slice(k);
  }

  let targets: string[] = [];
  if (cmd === "dd") {
    targets = args.filter((a) => a.startsWith("of=")).map((a) => a.slice(3));
  } else if (cmd === "cp" || cmd === "ln") {
    targets = destination(cmd, args);
  } else if (MUTATORS.has(cmd)) {
    targets = operands(cmd, args);
  }
  if (base === undefined) return { targets };
  const dir = base;
  return { targets: targets.map((t) => (path.isAbsolute(t) || t.startsWith("~") ? t : path.join(dir, t))) };
}

function segmentEffect(segment: Segment): CommandEffect {
  const redirectTargets: string[] = [];
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
      if (redirect === "out") redirectTargets.push(next.text);
    }
  }
  const effect = commandEffect(argv);
  return { ...effect, targets: [...redirectTargets, ...effect.targets] };
}

function touchesMain(command: string, cwd: string): boolean {
  let dir = cwd;
  for (const segment of parseSegments(command)) {
    const { targets, cd, script } = segmentEffect(segment);
    if (targets.some((target) => isMainCheckout(resolveTarget(target, dir)))) return true;
    if (script !== undefined && touchesMain(script, dir)) return true;
    if (cd !== undefined) dir = resolveTarget(cd, dir);
  }
  return false;
}

export function canCommandMutate(command: string, cwd: string): WorktreeGuardResult {
  if (typeof command !== "string" || command.length === 0) return SAFE;
  return touchesMain(command, cwd) ? { protected: true, reason: MESSAGE } : SAFE;
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
