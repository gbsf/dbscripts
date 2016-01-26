#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testAddSimplePackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		archreleasePackage "${pkgbase}"
		for arch in ${arches[@]}; do
			cp "${pkgdir}"/${pkgbase}/${pkgbase}-1-1-${arch}.pkg.tar.xz{,.sig} "${TMP}"
			"${curdir}"/../../db-add extra ${arch} "${TMP}/${pkgbase}-1-1-${arch}.pkg.tar.xz"
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

	for pkgbase in ${pkgs[@]}; do
		archreleasePackage "${pkgbase}"
	done

	for arch in ${arches[@]}; do
		add_pkgs=()
		for pkgbase in ${pkgs[@]}; do
			cp "${pkgdir}"/${pkgbase}/${pkgbase}-1-1-${arch}.pkg.tar.xz{,.sig} "${TMP}"
			add_pkgs[${#add_pkgs[*]}]="${TMP}/${pkgbase}-1-1-${arch}.pkg.tar.xz"
		done
		"${curdir}"/../../db-add extra ${arch} ${add_pkgs[@]}
	done

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			checkPackageDB extra ${pkgbase}-1-1-${arch}.pkg.tar.xz ${arch}
		done
	done
}

testAddAnyArchPackages() {
	local pkgs=('pkg-any-a' 'pkg-any-b')
	local pkgbase

	add_pkgs=()
	for pkgbase in ${pkgs[@]}; do
		archreleasePackage "${pkgbase}"
		cp "${pkgdir}"/${pkgbase}/${pkgbase}-1-1-any.pkg.tar.xz{,.sig} "${TMP}"
		add_pkgs[${#add_pkgs[*]}]="${TMP}/${pkgbase}-1-1-any.pkg.tar.xz"
	done
	"${curdir}"/../../db-add extra all ${add_pkgs[@]}

	for pkgbase in ${pkgs[@]}; do
		checkAnyPackageDB extra ${pkgbase}-1-1-any.pkg.tar.xz
	done
}

. "${curdir}/../lib/shunit2"
