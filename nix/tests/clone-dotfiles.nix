{ lib }:
let
  render = import ../lib/clone-dotfiles.nix { inherit lib; };

  hmScript = render {
    home = "/home/dandyrow";
    git = "/fake/git";
  };

  nixosScript = render {
    home = "/home/dandyrow";
    git = "/fake/git";
    caCert = "/fake/ca-bundle.crt";
    chownTo = "dandyrow:users";
  };
in
lib.runTests {
  # The clone must be idempotent — guarded on the target not already existing.
  testGuardsOnAbsentClone = {
    expr = lib.hasInfix ''[ ! -d "/home/dandyrow/.dotfiles" ]'' hmScript;
    expected = true;
  };

  testClonesRepoUrl = {
    expr = lib.hasInfix "https://github.com/dandyrow/dotfiles.git" hmScript;
    expected = true;
  };

  testUsesProvidedGitBinary = {
    expr = lib.hasInfix "/fake/git clone" hmScript;
    expected = true;
  };

  # The user adapter neither forwards a CA bundle nor chowns.
  testHmScriptHasNoCaCert = {
    expr = lib.hasInfix "GIT_SSL_CAINFO" hmScript;
    expected = false;
  };

  testHmScriptDoesNotChown = {
    expr = lib.hasInfix "chown" hmScript;
    expected = false;
  };

  # The root adapter forwards the CA bundle so the clone works during install.
  testNixosScriptForwardsCaCert = {
    expr = lib.hasInfix "GIT_SSL_CAINFO=/fake/ca-bundle.crt" nixosScript;
    expected = true;
  };

  # The root adapter hands ownership back to the user after cloning as root.
  testNixosScriptChownsToUser = {
    expr = lib.hasInfix ''chown -R dandyrow:users "/home/dandyrow/.dotfiles"'' nixosScript;
    expected = true;
  };
}
