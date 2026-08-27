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
    pkgs: attrs: map (attr: lib.getAttrFromPath (lib.splitString "." attr) pkgs) attrs;
in
{
  nvimToolPackages = json: pkgs: resolveNixpkgsAttrs pkgs (filterMasonOnly json);
}
