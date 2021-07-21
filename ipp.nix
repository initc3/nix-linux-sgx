{ lib,
  stdenvNoCC,
  fetchpatch,
  fetchurl,
  fetchFromGitHub,
  autoconf,
  automake,
  binutils,
  bison,
  cmake,
  file,
  flex,
  gcc,
  git,
  gnumake,
  gnum4,
  libtool,
  nasm,
  ocaml,
  ocamlPackages,
  openssl,
  perl,
  python3,
  texinfo
}:

stdenvNoCC.mkDerivation {
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
      url = "https://github.com/intel/linux-sgx/pull/730.patch";
      sha256 = "0xwlpm1r4rl4anfhjkr6fgz0gcyhr0ng46fv8iw9hfsh891yqb7z";
    })
    (fetchpatch {
      name = "ipp-crypto-makefile.patch";
      url = "https://github.com/intel/linux-sgx/pull/731.patch";
      sha256 = "1q9rsygm92kiwdj81yxp9q182rgb19kxir2m2r9l73hxwfz1cc0a";
    })
  ];
  buildInputs = [
    binutils
    autoconf
    automake
    libtool
    ocaml
    ocamlPackages.ocamlbuild
    file
    cmake
    gnum4
    openssl
    gcc
    gnumake
    texinfo
    bison
    flex
    perl
    python3
    git
    nasm
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
    make MITIGATION-CVE-2020-0551=LOAD
    make clean
    make MITIGATION-CVE-2020-0551=CF

    runHook postBuild
    '';
  postBuild = ''
    mkdir -p $out
    cp -r ./lib $out/lib
    cp -r ./inc $out/inc
    cp -r ./license $out/license
    ls -l ./inc/
  '';
  dontInstall = true;
  dontFixup = true;

  meta = with lib; {
    description = "Intel IPP Crypto library for SGX";
    homepage = "https://github.com/intel/linux-sgx";
    #maintainers = [ maintainers.sbellem ];
    platforms = platforms.linux;
    license = with licenses; [ asl20 bsd3 ];
  };
}
