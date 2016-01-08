#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testAddSimplePackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			archreleasePackage extra "${pkgbase}" "${arch}"
			signpkg "${TMP}/svn-packages-copy/${pkgbase}/trunk/${pkgbase}-1-1-${arch}.pkg.tar.xz"
			"${curdir}"/../../db-add extra ${arch} "${TMP}/svn-packages-copy/${pkgbase}/trunk/${pkgbase}-1-1-${arch}.pkg.tar.xz"
		done
	done

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			checkPackageDB extra ${pkgbase}-1-1-${arch}.pkg.tar.xz ${arch}
		done
	done
}

testAddMultiplePackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b')
	local pkgbase
	local arch

	for arch in ${arches[@]}; do
		add_pkgs=()
		for pkgbase in ${pkgs[@]}; do
			archreleasePackage extra "${pkgbase}" "${arch}"
			signpkg "${TMP}/svn-packages-copy/${pkgbase}/trunk/${pkgbase}-1-1-${arch}.pkg.tar.xz"
			add_pkgs[${#add_pkgs[*]}]="${TMP}/svn-packages-copy/${pkgbase}/trunk/${pkgbase}-1-1-${arch}.pkg.tar.xz"
		done
		"${curdir}"/../../db-add extra ${arch} ${add_pkgs[@]}
	done

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			checkPackageDB extra ${pkgbase}-1-1-${arch}.pkg.tar.xz ${arch}
		done
	done
}

. "${curdir}/../lib/shunit2"
