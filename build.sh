#!/bin/bash
export SHOULD_BUILD=yes
export VSCODE_ARCH=x64
export OS_NAME=linux
export CI_BUILD=no
export SHOULD_BUILD_DEB=no
export SHOULD_BUILD_APPIMAGE=no
export SHOULD_BUILD_TAR=no
export LANG=C.UTF-8
export GCC_IGNORE_WERROR=1
export AR=gcc-ar
export RANLIB=gcc-ranlib
export NM=gcc-nm
export CFLAGS="$CFLAGS -Ofast -falign-functions=32 -flto=auto -fno-semantic-interposition -mprefer-vector-width=256 "
export FCFLAGS="$FFLAGS -Ofast -falign-functions=32 -flto=auto -fno-semantic-interposition -mprefer-vector-width=256 "
export FFLAGS="$FFLAGS -Ofast -falign-functions=32 -flto=auto -fno-semantic-interposition -mprefer-vector-width=256 "
export CXXFLAGS="$CXXFLAGS -Ofast -falign-functions=32 -flto=auto -fno-semantic-interposition -mprefer-vector-width=256 "
export NODE_OPTIONS=--openssl-legacy-provider

# setup build environment
cd /home
swupd update --quiet -W 50
swupd bundle-add curl dnf --quiet -W 50
shopt -s expand_aliases && alias dnf='dnf -q -y --releasever=latest --disableplugin=changelog,needs_restarting'
dnf config-manager --add-repo https://cdn.download.clearlinux.org/current/x86_64/os
dnf groupinstall build srpm-build
echo 'exit 0' > /usr/lib/rpm/clr/brp-create-abi
dnf install createrepo_c curl gcc git python3-dev pypi-pip gnome-keyring \
    libgnome-keyring-dev wayland-dev  \
    iputils jq at-spi2-core-dev compat-fuse-soname2-dev fuse-dev GConf-lib \
    gdk-pixbuf-lib mesa-dev xvfb-run tzdata \
    gtk3-dev libnotify-dev libsecret-dev libX11-dev openssl-dev \
    wayland-protocols-dev libxkbfile-dev lsof polkit dbus-python sudo wget \
    fakeroot gperf cups-dev cairo-dev libpciaccess-dev libevdev-dev \
    libffi-dev ruby nodejs alsa-lib-dev
npm i -g yarn
export RELEASE_VERSION=`curl -s https://api.github.com/repos/VSCodium/vscodium/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`


git clone https://github.com/VSCodium/vscodium.git && cd vscodium
. get_repo.sh
. build.sh
pushd vscode
sed -i '65,105s|mime/|mime-|'  resources/linux/rpm/code.spec.template
sed -i '1s|^|%global abi_package %{nil}\n|' resources/linux/rpm/code.spec.template
# sed -i 's|@@VERSION@@|latest|' resources/linux/rpm/code.spec.template
yarn gulp "vscode-linux-${VSCODE_ARCH}-build-rpm"
popd
mkdir /home/RPMS
mv /home/vscodium/vscode/.build/linux/rpm/x86_64/rpmbuild/RPMS/x86_64/*.rpm /home/RPMS
