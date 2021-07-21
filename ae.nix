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
  texinfo,
  wget,
  which
}:

stdenvNoCC.mkDerivation {
  pname = "sgxae";
  version = "2.14a0";
  src = fetchFromGitHub {
    owner = "intel";
    repo = "linux-sgx";
    rev = "0cea078f17a24fb807e706409972d77f7a958db9";
    sha256 = "1cr2mkk459s270ng0yddgcryi0zc3dfmg9rmdrdh9mhy2mc1kx0g";
    fetchSubmodules = true;
  };
  dontConfigure = true;
  prePatch = ''
    patchShebangs ./linux/installer/bin/build-installpkg.sh
    patchShebangs ./linux/installer/common/sdk/createTarball.sh
    patchShebangs ./linux/installer/common/sdk/install.sh
    '';
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
    autoconf
    automake
    binutils
    bison
    cmake
    file
    flex
    gcc
    git
    gnumake
    gnum4
    libtool
    ocaml
    ocamlPackages.ocamlbuild
    openssl
    perl
    python3
    texinfo
    nasm
    wget
    which
  ];
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
    cd ../..

    make sdk_install_pkg
    patchShebangs ./linux/installer/bin/sgx_linux_x64_sdk_*.bin
    echo -e 'no\n'$out | ./linux/installer/bin/sgx_linux_x64_sdk_*.bin

    source $out/sgxsdk/environment

    export MITIGATION_CFLAGS+=-B$BINUTILS_DIR

    echo "Building le.so"
    cd ./psw/ae/le && make && cd ../../..
    echo "DONE building le.so"

    echo "Building pce.so"
    cd ./psw/ae/pce && make && cd ../../..
    echo "DONE building pce.so"

    echo "Building pve.so"
    cd ./psw/ae/pve && make && cd ../../..
    echo "DONE building pve.so"

    echo "Building qe.so"
    cd ./psw/ae/qe && make && cd ../../..
    echo "DONE building qe.so"

    echo "Building qe3.so"
    cd ./external/dcap_source/QuoteGeneration/quote_wrapper/quote/enclave/linux && make && cd ../../../../../../..
    echo "DONE building qe3.so"

    #patchShebangs ./external/dcap_source/QuoteVerification/prepare_sgxssl.sh
    #echo "Building qve.so"
    #cd ./external/dcap_source/QuoteVerification/QvE && make && cd ../../../..
    #echo "DONE building qve.so"

    runHook postBuild
    '';
  postBuild = ''
    mkdir $out/ae
    cp ./psw/ae/le/le.so $out/ae/
    cp ./psw/ae/pce/pce.so $out/ae/
    cp ./psw/ae/pve/pve.so $out/ae/
    cp ./psw/ae/qe/qe.so $out/ae/
    cp ./external/dcap_source/QuoteGeneration/quote_wrapper/quote/enclave/linux/qe3.so $out/ae/
    #cp ./external/dcap_source/QuoteVerification/QvE/qve.so $out/ae/
    '';
  dontInstall = true;
  dontFixup = true;

  meta = with lib; {
    description = "Intel SGX Architectural Enclaves (AEs) for Linux";
    homepage = "https://github.com/intel/linux-sgx";
    #maintainers = [ maintainers.sbellem ];
    platforms = platforms.linux;
    license = with licenses; [ bsd3 ];
  };
}
