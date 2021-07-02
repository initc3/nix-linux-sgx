{ lib,
  stdenvNoCC,
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
  version = "2.13.3a0";
  src = fetchFromGitHub {
    owner = "sbellem";
    repo = "linux-sgx";
    rev = "e6036d6edb4371f2acc64c50b7cb51e9dfa439a4";
    sha256 = "0znallianv3lp3y62cfdgp8gacpw516qg8cjxhz8bj5lv5qghchk";
    fetchSubmodules = true;
  };
  dontConfigure = true;
  prePatch = ''
    patchShebangs ./linux/installer/bin/build-installpkg.sh
    patchShebangs ./linux/installer/common/sdk/createTarball.sh
    patchShebangs ./linux/installer/common/sdk/install.sh
    '';
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
    export BINUTILS_DIR=$binutils/bin
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
