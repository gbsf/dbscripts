#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testRemovePackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b' 'pkg-split-a' 'pkg-split-b' 'pkg-simple-epoch')
	local pkgnames=('pkg-simple-a' 'pkg-simple-b' 'pkg-split-a'{1,2} 'pkg-split-b'{1,2} 'pkg-simple-epoch')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage extra ${pkgbase} ${arch}
		done
	done

	../db-update

	for pkgname in ${pkgnames[@]}; do
		for arch in ${arches[@]}; do
			# TODO: removing pkg-split-a/pkg-split-b won't work because
			# db-remove only removes single packages, not a group of split
			# packages. do we want that?
			../db-remove extra ${arch} ${pkgname}
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
	local pkgnames=('pkg-simple-a' 'pkg-simple-b' 'pkg-split-a'{1,2} 'pkg-split-b'{1,2} 'pkg-simple-epoch')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage extra ${pkgbase} ${arch}
		done
	done

	../db-update

	for arch in ${arches[@]}; do
			# TODO: removing pkg-split-a/pkg-split-b won't work because
			# db-remove only removes single packages, not a group of split
			# packages. do we want that?
		../db-remove extra ${arch} ${pkgnames[@]}
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

	../db-update

	for pkgbase in ${pkgs[@]}; do
		../db-remove extra all ${pkgbase}
	done

	for pkgbase in ${pkgs[@]}; do
		checkRemovedAnyPackage extra ${pkgbase}
	done
}

. "${curdir}/../lib/shunit2"
