#!/bin/bash
#
# Copyright (c) 2019 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

cidir=$(dirname "$0")
source "/etc/os-release" || "source /usr/lib/os-release"
source "${cidir}/lib.sh"

echo "Add epel repository"
epel_url="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
sudo -E yum install -y "$epel_url"

echo "Update repositories"
sudo -E yum -y update

echo "Install chronic"
sudo -E yum install -y moreutils

declare -A packages=(
	[kata_containers_dependencies]="libtool libtool-ltdl-devel device-mapper-persistent-data lvm2 device-mapper-devel libtool-ltdl bzip2 m4 patch gettext-devel automake alien autoconf bc pixman-devel coreutils" \
	[qemu_dependencies]="libcap-devel libcap-ng-devel libattr-devel libcap-ng-devel librbd1-devel flex libfdt-devel" \
	[nemu_dependencies]="brlapi" \
	[kernel_dependencies]="elfutils-libelf-devel flex" \
	[crio_dependencies]="glibc-static libseccomp-devel libassuan-devel libgpg-error-devel device-mapper-libs btrfs-progs-devel util-linux gpgme-devel glib2-devel glibc-devel libselinux-devel pkgconfig" \
	[bison_binary]="bison" \
	[build_tools]="python pkgconfig zlib-devel" \
	[os_tree]="ostree-devel" \
	[libudev-dev]="libgudev1-devel" \
	[yamllint]="yamllint"
	[metrics_dependencies]="smem jq" \
	[cri-containerd_dependencies]="libseccomp-devel btrfs-progs-devel" \
	[crudini]="crudini" \
	[procenv]="procenv" \
	[haveged]="haveged" \
	[gnu_parallel_dependencies]="perl bzip2 make" \
        [libsystemd]="systemd-devel" \
)

pkgs_to_install=${packages[@]}

for j in ${packages[@]}; do
	pkgs=$(echo "$j")
	info "The following package will be installed: $pkgs"
	pkgs_to_install+=" $pkgs"
done
chronic sudo -E yum -y install $pkgs_to_install

if [ "$(arch)" == "x86_64" ]; then
	VERSION_ID="7"
	echo "Install Kata Containers OBS repository for CentOS (see https://github.com/kata-containers/packaging/pull/555)"
	obs_url="${KATA_OBS_REPO_BASE}/CentOS_${VERSION_ID}/home:katacontainers:releases:$(arch):master.repo"
	sudo -E VERSION_ID=$VERSION_ID yum-config-manager --add-repo "$obs_url"
	repo_file="/etc/yum.repos.d/home\:katacontainers\:releases\:$(arch)\:master.repo"
	sudo bash -c "echo timeout=10 >> $repo_file"
	sudo bash -c "echo retries=2 >> $repo_file"
fi

if [ "$KATA_KSM_THROTTLER" == "yes" ]; then
	echo "Install ${KATA_KSM_THROTTLER_JOB}"
	sudo -E yum install ${KATA_KSM_THROTTLER_JOB}
fi
