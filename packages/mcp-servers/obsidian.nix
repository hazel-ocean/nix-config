{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
}:

buildNpmPackage rec {
  pname = "mcp-obsidian";
  version = "0.16.0";

  # Upstream's git lockfile omits resolved/integrity on 133 of 218 entries
  # (npm/cli#6301), so it cannot install offline. The published tarball ships
  # dist/ prebuilt, leaving only the four runtime deps to resolve.
  src = fetchurl {
    url = "https://registry.npmjs.org/@bitbonsai/mcpvault/-/mcpvault-${version}.tgz";
    hash = "sha512-HTGAi5eA9UM94Op9bfujz7UoCs51NcYQHU4Os3oXf5UX0QVrN3d1kQguL8erKFCgg7IeqH/PnbW23qRYmskzpg==";
  };

  # npm tarballs carry no lockfile. Regenerate with:
  #   npm install --package-lock-only --omit=dev
  # devDependencies stay in the published package.json, so drop them to match.
  postPatch = ''
    ${lib.getExe jq} 'del(.devDependencies, .scripts)' package.json > package.json.new
    mv package.json.new package.json
    cp ${./obsidian-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-naJHJgji4gwoKumAir+2wn+PefYXAMHF+Xl1I8OTbz8=";

  dontNpmBuild = true;

  # Upstream renamed the package to @bitbonsai/mcpvault (bin: mcpvault).
  # Rename for naming consistency with other MCP servers.
  postInstall = ''
    mv $out/bin/mcpvault $out/bin/mcp-obsidian
  '';

  meta = with lib; {
    description = "A universal AI bridge for Obsidian vaults using the Model Context Protocol";
    homepage = "https://github.com/bitbonsai/mcpvault";
    license = licenses.mit;
    mainProgram = "mcp-obsidian";
  };
}
