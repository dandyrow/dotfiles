{ lib }:
let
  filterMasonOnly =
    tools:
    lib.unique (
      map (t: if t ? nixpkgsAttr then t.nixpkgsAttr else t.name) (
        lib.filter (t: !(t.masonOnly or false)) tools
      )
    );

  resolveNixpkgsAttrs =
    pkgs: attrs:
    map (
      attr:
      if !(lib.hasAttrByPath (lib.splitString "." attr) pkgs) then
        throw "nvim-tools: cannot resolve '${attr}' — add nixpkgsAttr to tools.json for this tool"
      else
        lib.getAttrFromPath (lib.splitString "." attr) pkgs
    ) attrs;
in
{
  nvimToolPackages = json: pkgs: resolveNixpkgsAttrs pkgs (filterMasonOnly json);
}
