#!/bin/bash

# setup build environment
cd /home
swupd update --quiet 
swupd bundle-add curl dnf --quiet 
shopt -s expand_aliases && alias dnf='dnf -q -y --releasever=latest --disableplugin=changelog,needs_restarting'
dnf config-manager --add-repo https://cdn.download.clearlinux.org/current/x86_64/os
dnf groupinstall build srpm-build && dnf install createrepo_c
dnf groupinstall build srpm-build
dnf install createrepo_c curl gcc git python3-dev pypi-pip gnome-keyring libgnome-keyring-dev \
       iputils jq at-spi2-atk-dev compat-fuse-soname2-dev fuse-dev GConf-lib gdk-pixbuf-lib mesa-dev \
       gtk3-dev libnotify-dev libsecret-dev openssl-dev libX11-dev openssl-dev wayland-dev  \
       wayland-protocols-dev libxkbfile-dev lsof polkit dbus-python sudo wget xvfb-run tzdata \
       fakeroot gperf cups-dev cairo-dev libpciaccess-dev libevdev-dev libffi-dev ruby nodejs alsa-lib-dev
       

# fetch the source code
git clone https://github.com/VSCodium/vscodium.git && cd vscodium
./get_repo.sh
sed -i 's|yarn gulp "vscode-linux-${VSCODE_ARCH}-build-deb"|echo "skip the deb package"|' build.sh
sed -i 's|. ../build/linux/appimage/build.sh|echo "skip the appimage"|' build.sh

pushd vscode
sed -i '3s|.el7||' resources/linux/rpm/code.spec.template
sed -i '73s|mime/|mime-|' resources/linux/rpm/code.spec.template
sed -i '1s|^|%global abi_package %{nil}\n|' resources/linux/rpm/code.spec.template
popd

# compilation
npm i -g yarn
export SHOULD_BUILD="yes"
export VSCODE_ARCH=x64
export OS_NAME=linux
./build.sh
mkdir /home/RPMS
mv /home/vscodium/vscode/.build/linux/rpm/x86_64/rpmbuild/RPMS/x86_64/*.rpm /home/RPMS
