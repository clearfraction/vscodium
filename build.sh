#!/bin/bash

# setup build environment
cd /home
swupd update --quiet 
swupd bundle-add curl dnf --quiet 
shopt -s expand_aliases && alias dnf='dnf -q -y --releasever=latest --disableplugin=changelog,needs_restarting'
dnf config-manager --add-repo https://cdn.download.clearlinux.org/current/x86_64/os
dnf groupinstall build srpm-build && dnf install createrepo_c
dnf groupinstall build srpm-build
dnf install createrepo_c curl gcc git python3-dev pip-python3 gnome-keyring libgnome-keyring-dev \
       iputils jq at-spi2-atk-dev compat-fuse-soname2-dev fuse-dev GConf-lib gdk-pixbuf-lib mesa-dev \
       gtk3-dev libnotify-dev libsecret-dev openssl-dev libX11-dev openssl-dev wayland-dev  \
       wayland-protocols-dev libxkbfile-dev lsof polkit dbus-python sudo wget xvfb-run tzdata \
       fakeroot gperf cups-dev cairo-dev libpciaccess-dev libevdev-dev libffi-dev ruby nodejs alsa-lib-dev
       

# fetch the source code
export LATEST=`curl -s https://api.github.com/repos/microsoft/vscode/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`
git clone https://github.com/VSCodium/vscodium.git && cd vscodium
curl -L https://github.com/microsoft/vscode/archive/refs/tags/$LATEST.tar.gz -o /tmp/$LATEST.tar.gz
tar xfz /tmp/$LATEST.tar.gz -C /tmp/ && mv /tmp/vscode-$LATEST vscode && rm -rf /tmp/$LATEST.tar.gz


# compilation
npm i -g yarn
export SHOULD_BUILD="yes"
export VSCODE_ARCH=x64
export OS_NAME=linux
npm config set scripts-prepend-node-path true
. prepare_vscode.sh
cd vscode || exit
sed -i '3s|.el8||' resources/linux/rpm/code.spec.template
sed -i '73s|mime/|mime-|' resources/linux/rpm/code.spec.template
sed -i '1s|^|%global abi_package %{nil}\n|' resources/linux/rpm/code.spec.template
yarn install
yarn monaco-compile-check
yarn valid-layers-check
yarn gulp compile-build
yarn gulp compile-extension-media
yarn gulp compile-extensions-build
yarn gulp minify-vscode
yarn gulp vscode-linux-x64-min-ci
yarn gulp vscode-linux-x64-build-rpm


# deployment
count=`ls -1 $PWD/.build/linux/rpm/x86_64/rpmbuild/RPMS/x86_64/*.rpm 2>/dev/null | wc -l`
if [ $count != 0 ]
then
echo "Start deployment..."
mkdir RPMS
mv $PWD/.build/linux/rpm/x86_64/rpmbuild/RPMS/x86_64/*.rpm RPMS/
fi 
