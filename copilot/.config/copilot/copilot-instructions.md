# Machine-global Copilot CLI instructions

The machine-level guidance that applies to every session lives in a few
on-disk files that are the single source of truth. Before responding, read and
apply each one; if a file is absent, skip it.

- Apply the `unslop` skill. Read `~/.local/share/agents/skills/unslop/SKILL.md`
  and cut AI tells from any prose you produce (comments, PR/issue text, commit
  messages, chat replies).
- Follow the dependency decision ladder in
  `~/.config/agents/nix-native-deps.md` for any system/CLI tool need.
