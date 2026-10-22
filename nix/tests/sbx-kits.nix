{ lib, pkgs }:
let
  evalKits =
    isWsl:
    (lib.evalModules {
      specialArgs = { inherit pkgs; };
      modules = [
        ../modules/base/sbx-kits.nix
        {
          options.sbx = {
            enable = lib.mkEnableOption "sbx";
            kits = lib.mkOption {
              type = lib.types.attrsOf lib.types.package;
              default = { };
            };
          };
          options.wsl.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          config = {
            sbx.enable = true;
            wsl.enable = isWsl;
          };
        }
      ];
    }).config.sbx.kits;

  hostKits = evalKits false;
  wslKits = evalKits true;

  hasCorpPem = builtins.pathExists /etc/nixos/corp.pem;

  # Manual check: `sbx kit validate <zip>`; sbx is unfree and absent from CI.
  checkZip =
    name: drv: body:
    pkgs.runCommand "test-sbx-kit-${name}"
      {
        nativeBuildInputs = [
          pkgs.unzip
          pkgs.gnugrep
          pkgs.yq-go
        ];
      }
      ''
        unzip -q ${drv} -d unpack
        test -f unpack/spec.yaml || { echo "${name}: missing spec.yaml"; exit 1; }
        yq -e '.name == "${name}"' unpack/spec.yaml >/dev/null || { echo "${name}: wrong name"; exit 1; }
        ${body}
        touch $out
      '';

  agentGateCheck = checkZip "agent-gate" hostKits.agent-gate ''
    test -x unpack/files/home/agent-gate/betterleaks
    test -x unpack/files/home/agent-gate/pre-push
    yq -e '.setup.install[0].command | contains("core.hooksPath")' unpack/spec.yaml >/dev/null
    yq -e '.setup.install[0].user == "0"' unpack/spec.yaml >/dev/null
  '';

  opencodeCopilotCheck = checkZip "opencode-copilot" wslKits.opencode-copilot ''
    yq -e '.requires.agent == "opencode"' unpack/spec.yaml >/dev/null
    yq -e '.credentials[0].service == "opencode-copilot"' unpack/spec.yaml >/dev/null
    yq -e '.credentials[0].apiKey.inject[0].domain == "api.githubcopilot.com"' unpack/spec.yaml >/dev/null
    yq -e '.credentials[0].apiKey.inject[0].scheme == "bearer"' unpack/spec.yaml >/dev/null
  '';

  corpCaCheck = checkZip "corp-ca" wslKits.corp-ca ''
    test "$(find unpack/files/home/corp-ca -name '*.crt' | wc -l)" -ge 1
  '';

  hostScopeCheck = pkgs.runCommand "test-sbx-kits-host-scope" { } ''
    ${lib.optionalString (hostKits ? corp-ca) ''
      echo "corp-ca leaked to a non-WSL host"
      exit 1
    ''}
    ${lib.optionalString (hostKits ? opencode-copilot) ''
      echo "opencode-copilot leaked to a non-WSL host"
      exit 1
    ''}
    ${lib.optionalString (!(hostKits ? agent-gate)) ''
      echo "agent-gate missing on a non-WSL host"
      exit 1
    ''}
    touch $out
  '';

  checks = [
    agentGateCheck
    opencodeCopilotCheck
    hostScopeCheck
  ]
  ++ lib.optional hasCorpPem corpCaCheck;
in
assert (wslKits ? corp-ca) == hasCorpPem;
pkgs.runCommand "test-sbx-kits" { buildInputs = checks; } "touch $out"
