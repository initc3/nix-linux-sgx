{ lib
, stdenv
, fetchpatch
, fetchurl
, fetchFromGitHub
, autoconf
, automake
, binutils
, bison
, cmake
, file
, flex
, git
, gnum4
, libtool
, nasm
, ocaml
, ocamlPackages
, openssl
, perl
, python3
, texinfo
}:

stdenv.mkDerivation {
  pname = "ippcrypto";
  version = "ippcp_2020u3";
  src = fetchFromGitHub {
    owner = "intel";
    repo = "linux-sgx";
    rev = "0cea078f17a24fb807e706409972d77f7a958db9";
    sha256 = "1cr2mkk459s270ng0yddgcryi0zc3dfmg9rmdrdh9mhy2mc1kx0g";
    fetchSubmodules = true;
  };
  patches = [
    (fetchpatch {
      name = "replace-bin-cp-with-cp.patch";
      url = "https://github.com/intel/linux-sgx/commit/e0db5291d46d1c124980719d63829d65f89cf2c7.patch";
      sha256 = "0xwlpm1r4rl4anfhjkr6fgz0gcyhr0ng46fv8iw9hfsh891yqb7z";
    })
    (fetchpatch {
      name = "sgx_ippcp.h.patch";
      url = "https://github.com/intel/linux-sgx/commit/e5929083f8161a8e7404afc0577936003fbb9d0b.patch";
      sha256 = "12bgs9rxlq82hn5prl9qz2r4mwypink8hzdz4cki4k4cmkw961f5";
    })
    (fetchpatch {
      name = "ipp-crypto-makefile.patch";
      url = "https://github.com/intel/linux-sgx/commit/b1e1b2e9743c21460c7ab7637099818f656f9dd3.patch";
      sha256 = "14h6xkk7m89mkjc75r8parll8pmq493incq5snwswsbdzibrdi68";
    })
  ];
  nativeBuildInputs = [
    autoconf
    automake
    bison
    cmake
    file
    flex
    git
    gnum4
    libtool
    nasm
    ocaml
    ocamlPackages.ocamlbuild
    openssl
    perl
    texinfo
  ];
  buildInputs = [
    binutils
    python3
  ];
  dontConfigure = true;
  # sgx expects binutils to be under /usr/local/bin by default
  preBuild = ''
    export BINUTILS_DIR=${binutils}/bin
  '';
  buildPhase = ''
    runHook preBuild

    cd external/ippcp_internal/
    make
    make clean
    make MITIGATION-CVE-2020-0551=LOAD
    make clean
    make MITIGATION-CVE-2020-0551=CF

    runHook postBuild
  '';
  installPhase = ''
    mkdir -p $out
    cp -r ./lib $out/lib
    cp -r ./inc $out/inc
    cp -r ./license $out/license
    ls -l ./inc/
  '';

  meta = with lib; {
    description = "Intel IPP Crypto library for SGX";
    homepage = "https://github.com/intel/linux-sgx";
    #maintainers = [ maintainers.sbellem ];
    platforms = platforms.linux;
    license = with licenses; [ asl20 bsd3 ];
  };
}
