# Patches for upstream bugs. Every workaround in this repo carries an
# `# upstream:` tag naming the issue, or the condition that makes it safe to
# delete. `rg '# upstream:'` lists them all.
final: prev:
let
  inherit (prev) lib stdenv;
in
lib.optionalAttrs stdenv.hostPlatform.isDarwin {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pyfinal: pyprev: {
      # upstream: https://github.com/NixOS/nixpkgs/issues/320196
      # Darwin links the dylib by its @rpath install name without adding one.
      curl-cffi = pyprev.curl-cffi.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          install_name_tool -add_rpath ${lib.getLib final.curl-impersonate}/lib \
            $out/${pyprev.python.sitePackages}/curl_cffi/_wrapper.abi3.so
        '';
        # upstream: none filed; libcurl sends an unaligned WS frame (curl 43).
        # nixpkgs already disables the sync sibling, but not this one.
        disabledTests = (old.disabledTests or [ ]) ++ [ "test_large_message_echo" ];
      });
    })
  ];
}
// lib.optionalAttrs stdenv.hostPlatform.isLinux {
  # upstream: none filed; drop when openldap's i686 test suite passes.
  openldap = prev.openldap.overrideAttrs (_: {
    doCheck = !stdenv.hostPlatform.isi686;
  });
}
