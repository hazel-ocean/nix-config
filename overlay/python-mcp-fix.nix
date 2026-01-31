# Fix for python mcp package build failure
# The upstream nixpkgs postPatch tries to substitute a pattern that no longer exists
# in the test file. This overlay removes the broken postPatch.
final: prev: {
  python313Packages = prev.python313Packages.override {
    overrides = pfinal: pprev: {
      mcp = pprev.mcp.overrideAttrs (old: {
        postPatch = "";
      });
    };
  };
  python312Packages = prev.python312Packages.override {
    overrides = pfinal: pprev: {
      mcp = pprev.mcp.overrideAttrs (old: {
        postPatch = "";
      });
    };
  };
}
