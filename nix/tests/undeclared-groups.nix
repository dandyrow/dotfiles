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
    testDeclaredGroupsAreAccepted = {
      expr = undeclaredGroupsIn {
        users.alice.extraGroups = [
          "wheel"
          "lpadmin"
        ];
        groups = {
          wheel = { };
          lpadmin = { };
        };
      };
      expected = [ ];
    };

    testUndeclaredGroupIsReported = {
      expr = undeclaredGroupsIn {
        users.alice.extraGroups = [
          "wheel"
          "print"
        ];
        groups.wheel = { };
      };
      expected = [
        {
          user = "alice";
          group = "print";
        }
      ];
    };

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

    testMemberlessGroupIsStillDeclared = {
      expr = undeclaredGroupsIn {
        users.alice.extraGroups = [ "lpadmin" ];
        groups.lpadmin.members = [ ];
      };
      expected = [ ];
    };

    testUserWithNoExtraGroupsIsIgnored = {
      expr = undeclaredGroupsIn {
        users.alice = { };
        groups = { };
      };
      expected = [ ];
    };
  }
  // hostTests
)
