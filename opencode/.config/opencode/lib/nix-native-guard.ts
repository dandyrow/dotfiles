export type RuleId =
  | "pipe-to-shell"
  | "global-npm-install"
  | "pipx-install"
  | "cargo-install"
  | "go-install"
  | "bare-pip-install";

export interface GuardResult {
  blocked: boolean;
  rule?: RuleId;
  reason?: string;
}

const ALLOW: GuardResult = { blocked: false };

const VENV_PATH_PIP =
  /(?:^|[\s;&|=(])(?:\.\/)?\.?venv\/bin\/pip[0-9.]*\s+install\b/;
const VENV_ACTIVATE = /(?:^|[\s;&|])(?:source|\.)\s+\S*activate\b/;
const PIP_INSTALL = /\bpip[0-9.]*\s+install\b/;
const PIP_REQUIREMENT = /(?:^|\s)(?:-r|--requirement)\b/;

const BLOCKERS: { rule: RuleId; test: (cmd: string) => boolean }[] = [
  {
    rule: "pipe-to-shell",
    test: (cmd) =>
      /\b(?:curl|wget)\b.*\|\s*(?:sudo\s+)?(?:sh|bash|zsh|dash|ksh|fish)\b/is.test(
        cmd,
      ),
  },
  {
    rule: "global-npm-install",
    test: (cmd) =>
      /\bnpm\s+(?:i|in|install|add)\b[^&|;\n]*?\s(?:-g|--global)(?=\s|$)/.test(cmd),
  },
  { rule: "pipx-install", test: (cmd) => /\bpipx\s+install\b/.test(cmd) },
  { rule: "cargo-install", test: (cmd) => /\bcargo\s+install\b/.test(cmd) },
  { rule: "go-install", test: (cmd) => /\bgo\s+install\b/.test(cmd) },
  {
    rule: "bare-pip-install",
    test: (cmd) => {
      if (!PIP_INSTALL.test(cmd)) return false;
      // Only a command-string-visible venv exempts pip; process env-var venv state is unreliable here.
      const venvActive = VENV_ACTIVATE.test(cmd);
      // The -r must belong to the pip call itself, so evaluate each pip segment on its own.
      for (const segment of cmd.split(/[;&|\n]+/)) {
        if (!PIP_INSTALL.test(segment)) continue;
        const venvForm = venvActive || VENV_PATH_PIP.test(segment);
        if (!(venvForm && PIP_REQUIREMENT.test(segment))) return true;
      }
      return false;
    },
  },
];

const MESSAGE =
  "Blocked: this is an imperative, un-reproducible install. Follow the nix-native dependency workflow — run the tool ephemerally (`nix run nixpkgs#<pkg>` / `nix shell nixpkgs#<pkg>`) or propose adding it to the Nix config. See nix-native-deps guidance.";

export function evaluateBashCommand(command: string): GuardResult {
  if (typeof command !== "string" || command.length === 0) return ALLOW;
  for (const { rule, test } of BLOCKERS) {
    if (test(command)) return { blocked: true, rule, reason: MESSAGE };
  }
  return ALLOW;
}
