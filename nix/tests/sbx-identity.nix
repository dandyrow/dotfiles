{ lib, pkgs }:
let
  eval =
    { osConfig }:
    (lib.evalModules {
      specialArgs = { inherit osConfig pkgs; };
      modules = [
        ../home/facts.nix
        ../home/core/sbx-identity.nix
        {
          options.home = {
            packages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
            };
            homeDirectory = lib.mkOption {
              type = lib.types.str;
              default = "/home/dandyrow";
            };
          };
        }
      ];
    }).config;

  identity = osConfig: (eval { inherit osConfig; }).dandyrow.sbxIdentity;
  packageNames =
    osConfig: lib.sort (a: b: a < b) (map (p: p.name or "") (eval { inherit osConfig; }).home.packages);

  enabledHost = {
    sbx.enable = true;
    networking.hostName = "DansSpectre";
  };

  wslHost = {
    sbx.enable = true;
    wsl.enable = true;
    networking.hostName = "WSL";
  };
in
lib.runTests {
  testStandaloneIsDisabled = {
    expr = (identity null).enable;
    expected = false;
  };

  testHostWithoutSbxIsDisabled = {
    expr =
      (identity {
        sbx.enable = false;
        networking.hostName = "DansSpectre";
      }).enable;
    expected = false;
  };

  testSbxHostIsEnabled = {
    expr = (identity enabledHost).enable;
    expected = true;
  };

  testWslIsDetected = {
    expr = (identity wslHost).isWsl;
    expected = true;
  };

  testGdmHostIsNotWsl = {
    expr = (identity enabledHost).isWsl;
    expected = false;
  };

  testStandaloneIsNotWsl = {
    expr = (identity null).isWsl;
    expected = false;
  };

  testWslGitIdentity = {
    expr = (identity wslHost).gitIdentity;
    expected = {
      name = "Copilot";
      email = "198982749+Copilot@users.noreply.github.com";
    };
  };

  testGdmGitIdentity = {
    expr = (identity enabledHost).gitIdentity;
    expected = {
      name = "opencode-agent[bot]";
      email = "219766164+opencode-agent[bot]@users.noreply.github.com";
    };
  };

  testWslUsesFileBackend = {
    expr = (identity wslHost).github.backend;
    expected = "file";
  };

  testGdmUsesKeyringBackend = {
    expr = (identity enabledHost).github.backend;
    expected = "keyring";
  };

  testWslAppName = {
    expr = (identity wslHost).github.appName;
    expected = "dandyrow-agent-wsl";
  };

  testGdmAppName = {
    expr = (identity enabledHost).github.appName;
    expected = "dandyrow-agent-dansspectre";
  };

  testEnabledHostInstallsIdentityScripts = {
    expr = packageNames enabledHost;
    expected = [
      "sbx-github-app-register"
      "sbx-github-mint"
    ];
  };

  testDisabledHostInstallsNoScripts = {
    expr = packageNames {
      sbx.enable = false;
      networking.hostName = "DansSpectre";
    };
    expected = [ ];
  };
}
