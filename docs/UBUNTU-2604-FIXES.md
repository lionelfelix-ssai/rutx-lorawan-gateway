# Building on Ubuntu 26.04

Ubuntu 26.04 ships GCC 15, CMake 3.31, and Python 3.14, which cause compatibility issues with the Teltonika SDK (designed for GCC 12-13).

## GCC 15: Install GCC 13

    sudo apt install -y gcc-13 g++-13
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100

## CMake 3.31+: Add policy minimum globally

In include/cmake.mk, add after CMAKE_FIND_PACKAGE_NO_SYSTEM_PACKAGE_REGISTRY:

    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \

## Python 3.14

    sudo apt install -y python-is-python3
    # Install Python 3.11 from deadsnakes PPA and set as default

## squashfskit4 date parsing

    sed -i 's/date -r "$1" "$2"/date -d "@$1" "$2"/' \
      build_dir/host/squashfskit-v4.14/squashfs-tools/version.sh

## e2fsprogs missing directories

    mkdir -p staging_dir/host/include/{e2p,ext2fs,quota,blkid,uuid,ss,et}
    mkdir -p staging_dir/host/share/{et,ss}
    mkdir -p staging_dir/host/share/man/man{1,3,5,8}
    mkdir -p staging_dir/host/lib/pkgconfig
