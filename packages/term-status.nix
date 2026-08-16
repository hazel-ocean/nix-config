{
  stdenv,
  lib,
  fetchFromGitHub,
  rustPlatform,
  openssl,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "term-status";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "oceanlewis";
    repo = pname;
    rev = "a72f98771402261814c4d68f3f60bece7caf0842";
    sha256 = "MxW8YUu7Fr4VQHIpnOovFPXzbrp46ZeiSm3lmzTpb4w=";
  };

  cargoSha256 = "qfesMUUVPVWQomqRHEltB1abzPAdz0fG3Hmg0BJRYH8=";

  buildInputs = [ openssl ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ darwin.Security ];

  meta = with lib; {
    description = "Replace my silly shell prompt with a silly rust program that does the same thing!";
    homepage = "https://github.com/oceanlewis/term-status";
    license = licenses.mit;
  };
}
