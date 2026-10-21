{
  lib,
  buildNpmPackage,
  makeWrapper,
  nodejs,
}:
buildNpmPackage {
  pname = "canvas-kit-mcp";
  version = (lib.importJSON ./canvas-kit-mcp/package.json).version;
  src = ./canvas-kit-mcp;
  npmDepsHash = "sha256-ZYN0xNmma62Td73mucwt+gsTvNRzNwA8IpkTNnDF6rA=";
  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    makeWrapper ${nodejs}/bin/node "$out/bin/canvas-kit-mcp" \
      --add-flags "$out/lib/node_modules/canvas-kit-mcp-runtime/node_modules/@workday/canvas-kit-mcp/dist/cli.js"
  '';
  meta = {
    description = "Canvas Kit documentation MCP server";
    homepage = "https://github.com/Workday/canvas-kit";
    license = lib.licenses.asl20;
    mainProgram = "canvas-kit-mcp";
  };
}
