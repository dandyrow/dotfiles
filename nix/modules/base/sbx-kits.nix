{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkKit =
    name: src:
    pkgs.runCommand "sbx-kit-${name}.zip" { nativeBuildInputs = [ pkgs.zip ]; } ''
      cp -r ${src} ./kit
      chmod -R u+w ./kit
      (cd ./kit && zip -qr $out .)
    '';

  agentGateSrc = ../../sbx-kits/agent-gate;
  corpCaSrc = ../../sbx-kits/corp-ca;
  opencodeCopilotSrc = ../../sbx-kits/opencode-copilot;

  isWsl = config.wsl.enable or false;

  corpCaKit = lib.optionalAttrs (isWsl && builtins.pathExists /etc/nixos/corp.pem) (
    let
      certs = pkgs.runCommand "corp-ca-certs" { } ''
        mkdir -p $out/files/home/corp-ca
        awk -v dir="$out/files/home/corp-ca" \
          '/-----BEGIN CERTIFICATE-----/ { n++ } n { print > (dir "/cert-" n ".crt") }' \
          ${/etc/nixos/corp.pem}
        test "$(find $out/files/home/corp-ca -name '*.crt' | wc -l)" -ge 1
        cp ${corpCaSrc}/spec.yaml $out/
      '';
    in
    {
      corp-ca = mkKit "corp-ca" certs;
    }
  );

  agentGateKit = mkKit "agent-gate" (
    pkgs.runCommand "agent-gate-src" { } ''
      mkdir -p $out/files/home/agent-gate
      cp ${agentGateSrc}/spec.yaml $out/
      cp ${agentGateSrc}/pre-push $out/files/home/agent-gate/
      cp ${pkgs.betterleaks}/bin/betterleaks $out/files/home/agent-gate/
      chmod 755 $out/files/home/agent-gate/betterleaks $out/files/home/agent-gate/pre-push
    ''
  );

  opencodeCopilotKit = lib.optionalAttrs isWsl {
    opencode-copilot = mkKit "opencode-copilot" (
      pkgs.runCommand "opencode-copilot-src" { } ''
        mkdir -p $out
        cp ${opencodeCopilotSrc}/spec.yaml $out/
      ''
    );
  };
in
{
  config = lib.mkIf config.sbx.enable {
    sbx.kits = lib.mkMerge [
      { agent-gate = agentGateKit; }
      corpCaKit
      opencodeCopilotKit
    ];
  };
}
