{ lib }:
let
  fakeKit = {
    type = "derivation";
    name = "agent-gate.zip";
    outPath = "/fake/agent-gate.zip";
  };

  eval =
    {
      enable,
      kits ? { },
    }:
    (lib.evalModules {
      modules = [
        ../modules/base/sbx.nix
        {
          _module.args.pkgs = {
            docker-sbx = {
              type = "derivation";
              name = "docker-sbx";
              pname = "docker-sbx";
              outPath = "/fake/docker-sbx";
            };
          };
        }
        {
          options.environment.systemPackages = lib.mkOption {
            type = lib.types.listOf lib.types.anything;
            default = [ ];
          };
          options.environment.etc = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          config.sbx = {
            inherit enable kits;
          };
        }
      ];
    }).config;

  pnames = config: map (p: p.pname or "") config.environment.systemPackages;
in
lib.runTests {
  testDisabledAddsNoPackage = {
    expr = pnames (eval {
      enable = false;
    });
    expected = [ ];
  };

  testEnabledAddsDockerSbx = {
    expr = builtins.elem "docker-sbx" (
      pnames (eval {
        enable = true;
      })
    );
    expected = true;
  };

  testEnabledInstallsKitZip = {
    expr =
      (eval {
        enable = true;
        kits = {
          agent-gate = fakeKit;
        };
      }).environment.etc."sbx-kits/agent-gate.zip".source;
    expected = fakeKit;
  };

  testDisabledInstallsNoKit = {
    expr =
      (eval {
        enable = false;
        kits = {
          agent-gate = fakeKit;
        };
      }).environment.etc;
    expected = { };
  };
}
