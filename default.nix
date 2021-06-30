let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  
  sgx = with pkgs; {
    sdk = callPackage ./sdk.nix { };
    ipp = callPackage ./ipp.nix { };
    ae = callPackage ./ae.nix { };
  };
in sgx
