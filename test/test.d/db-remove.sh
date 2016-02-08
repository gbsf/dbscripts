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

testRemoveSplitArchPackages() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-split-c'
	local arch

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch} ${pkgbase}1
	done
	releasePackage extra ${pkgbase} any ${pkgbase}2

	"${curdir}"/../../db-update

	"${curdir}"/../../db-remove extra all ${pkgbase}1

	for arch in ${arches[@]}; do
		checkRemovedPackage extra ${pkgbase}1 ${arch}
	done
	checkRemovedAnyPackage extra ${pkgbase}2
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

testRemoveDebugPackage() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-debug-a'
	local arch

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch} ${pkgbase}
	done

	"${curdir}"/../../db-update

	"${curdir}"/../../db-remove extra all ${pkgbase}

	for arch in ${arches[@]}; do
		checkRemovedPackage extra ${pkgbase} ${arch}
		checkRemovedPackage extra-${DEBUGSUFFIX} ${pkgbase}-${DEBUGSUFFIX} ${arch}
	done
}

testRemoveOnlyDebugPackage() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-debug-a'
	local arch

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch} ${pkgbase}
	done

	"${curdir}"/../../db-update

	"${curdir}"/../../db-remove extra-${DEBUGSUFFIX} all ${pkgbase}-${DEBUGSUFFIX}

	for arch in ${arches[@]}; do
		checkPackage extra ${pkgbase}-1-1-${arch}.pkg.tar.xz ${arch}
		checkRemovedPackage extra-${DEBUGSUFFIX} ${pkgbase}-${DEBUGSUFFIX} ${arch}
	done
}

. "${curdir}/../lib/shunit2"
