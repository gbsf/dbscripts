#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testRemovePackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b' 'pkg-split-a' 'pkg-split-b' 'pkg-simple-epoch')
	local pkgnames=('pkg-simple-a' 'pkg-simple-b' 'pkg-split-a'{1,2} 'pkg-split-b'{1,2,3} 'pkg-simple-epoch')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage extra ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	for pkgname in ${pkgnames[@]}; do
		for arch in ${arches[@]}; do
			"${curdir}"/../../db-remove extra ${arch} ${pkgname}
		done
	done

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			checkRemovedPackage extra ${pkgbase} ${arch}
		done
	done

	for pkgname in ${pkgnames[@]}; do
		for arch in ${arches[@]}; do
			checkRemovedPackage extra ${pkgname} ${arch}
		done
	done
}

testRemoveMultiplePackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b' 'pkg-split-a' 'pkg-split-b' 'pkg-simple-epoch')
	local pkgnames=('pkg-simple-a' 'pkg-simple-b' 'pkg-split-a'{1,2} 'pkg-split-b'{1,2,3} 'pkg-simple-epoch')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage extra ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	for arch in ${arches[@]}; do
		"${curdir}"/../../db-remove extra ${arch} ${pkgnames[@]}
	done

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			checkRemovedPackage extra ${pkgbase} ${arch}
		done
	done

	for pkgname in ${pkgnames[@]}; do
		for arch in ${arches[@]}; do
			checkRemovedPackage extra ${pkgname} ${arch}
		done
	done
}

testRemoveAnyPackages() {
	local pkgs=('pkg-any-a' 'pkg-any-b')
	local pkgbase

	for pkgbase in ${pkgs[@]}; do
		releasePackage extra ${pkgbase} any
	done

	"${curdir}"/../../db-update

	for pkgbase in ${pkgs[@]}; do
		"${curdir}"/../../db-remove extra all ${pkgbase}
	done

	for pkgbase in ${pkgs[@]}; do
		checkRemovedAnyPackage extra ${pkgbase}
	done
}

testRemoveSingleArch() {
	local pkgs=('pkg-any-a' 'pkg-any-b')
	local pkgbase

	for pkgbase in ${pkgs[@]}; do
		releasePackage extra ${pkgbase} any
	done

	"${curdir}"/../../db-update

	"${curdir}"/../../db-remove extra i686 pkg-any-a

	checkRemovedPackage extra pkg-any-a i686
	checkPackage extra pkg-any-a-1-1-any.pkg.tar.xz x86_64
	checkPackage extra pkg-any-b-1-1-any.pkg.tar.xz i686
	checkPackage extra pkg-any-b-1-1-any.pkg.tar.xz x86_64
}

. "${curdir}/../lib/shunit2"
