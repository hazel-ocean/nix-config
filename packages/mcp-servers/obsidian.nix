{
  writeShellApplication,
  nodejs,
}:

# Fetched by npx at run time rather than built here: upstream's lockfile omits
# resolved/integrity on most entries, so it cannot install offline.
writeShellApplication {
  name = "mcp-obsidian";

  runtimeInputs = [ nodejs ];

  text = ''
    exec npx --yes "@bitbonsai/mcpvault@0.16.0" "$@"
  '';
}
