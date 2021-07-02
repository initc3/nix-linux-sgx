let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  
  sgx = with pkgs; {
    sgxsdk = callPackage ./sdk.nix { };
    ipp-crypto = callPackage ./ipp.nix { };
    sgx-ae = callPackage ./ae.nix { };
  };
in sgx
