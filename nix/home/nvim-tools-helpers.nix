{ lib }:
{
  # Keep only tools without masonOnly, then resolve to nixpkgs attribute names.
  filterMasonOnly =
    tools:
    lib.unique (
      map (t: if t ? nixpkgsAttr then t.nixpkgsAttr else t.name) (
        lib.filter (t: !(t.masonOnly or false)) tools
      )
    );

  # Resolve attribute name strings to actual nixpkgs packages.
  resolveNixpkgsAttrs =
    pkgs: attrs: map (attr: lib.getAttrFromPath (lib.splitString "." attr) pkgs) attrs;
}
