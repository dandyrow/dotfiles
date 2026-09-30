{ lib, nixosConfigurations }:
let
  # NixOS resolves membership from the group's side, so an undeclared name is inert rather than an error.
  undeclaredGroupsIn =
    { users, groups }:
    lib.concatLists (
      lib.mapAttrsToList (
        user: userConfig:
        map (group: { inherit user group; }) (
          lib.filter (group: !(groups ? ${group})) (userConfig.extraGroups or [ ])
        )
      ) users
    );

  # The helper above is test-local: nothing in production performs this check, so
  # the per-host tests are the ones that can fail on a real config change. The
  # synthetic case exists only to pin the helper's output shape.
  hostTests = lib.mapAttrs' (host: nixos: {
    name = "testNoUndeclaredGroupsOn${host}";
    value = {
      expr = undeclaredGroupsIn { inherit (nixos.config.users) users groups; };
      expected = [ ];
    };
  }) nixosConfigurations;
in
lib.runTests (
  {
    testEveryUndeclaredNameIsReported = {
      expr = undeclaredGroupsIn {
        users = {
          alice.extraGroups = [ "print" ];
          bob.extraGroups = [ "scanner" ];
        };
        groups = { };
      };
      expected = [
        {
          user = "alice";
          group = "print";
        }
        {
          user = "bob";
          group = "scanner";
        }
      ];
    };
  }
  // hostTests
)
