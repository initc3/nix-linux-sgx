# nix-linux-sgx
Nix derivations for the C++ Linux SGX SDK, IPP-Crypto library, and
Architectural Enclaves.

This work is of particular interest for enclave applications that rely on the
C++ Linux SGX SDK and wish to have reproducible enclave builds. Reproducible
enclave builds can be of vital importance in remote attestation, and also
for [sealing data](https://software.intel.com/content/www/us/en/develop/blogs/introduction-to-intel-sgx-sealing.html)
with an enclave policy.

This work originated from working with the Linux SGX reproducible environment
found at https://github.com/intel/linux-sgx/tree/master/linux/reproducibility.
Enclave developers and builders can write nix derivations for their enclaves
and specify the SGX SDK as a dependency just like any other dependency.


## Install
We hope to soon have the SGX SDK nix package merged into the nixpkgs
repository (see draft pull request at
https://github.com/NixOS/nixpkgs/pull/126990) . Until then you can install the
SGX SDK nix package from [cachix](https://cachix.org/) like so:

```shell
nix-env -iA sgxsdk -f https://github.com/initc3/nix-linux-sgx/tarball/main \
    --substituters https://initc3.cachix.org \
    --trusted-public-keys initc3.cachix.org-1:tt+5+CggCBEur43PcFgrkNxdlOFBnoB01aLe6y6yMcA=
```
If you are writing a nix derivation, you can use the following approach, using
niv:

```shell
niv add initc3/nix-linux-sgx --name sgx
```

Then you can write your nix derivation like so:

```nix
let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  sgx = import sources.sgx;
in
pkgs.stdenv.mkDerivation {
  name = "sgx-myapp";
  src = pkgs.fetchFromGitHub {
    owner = "myrepo";
    repo = "sgx-myapp";
    rev = "a1...";
    sha256 = "b2...";
  };
  preConfigure = ''
    export SGX_SDK=${sgx.sgxsdk}/sgxsdk
    export PATH=$PATH:$SGX_SDK/bin:$SGX_SDK/bin/x64
    export PKG_CONFIG_PATH=$SGX_SDK/pkgconfig
    export LD_LIBRARY_PATH=$SGX_SDK/sdk_libs
    '';
  buildInputs = with pkgs; [
    sgx.sgxsdk
    # ...
 ```

Install [`cachix`](https://docs.cachix.org/installation.html):

```shell
nix-env -iA cachix -f https://cachix.org/api/v1/install
```

Add the `initc3` cache:

```shell
cachix use initc3
```

Invoking `nix-build` to build your derivation should automatically pull
the sgxsdk binary dependency from the cache.
