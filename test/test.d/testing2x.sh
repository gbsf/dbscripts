#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testTesting2xAnyPackage() {
	releasePackage core pkg-any-a any
	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/pkg-any-a/trunk/" >/dev/null
	sed 's/pkgrel=1/pkgrel=2/g' -i PKGBUILD
	arch_svn commit -q -m"update pkg to pkgrel=2" >/dev/null
	popd >/dev/null

	releasePackage testing pkg-any-a any
	"${curdir}"/../../db-update

	"${curdir}"/../../testing2x pkg-any-a

	checkAnyPackage core pkg-any-a-1-2-any.pkg.tar.xz any
	checkRemovedAnyPackage testing pkg-any-a
}

testTesting2xMultiArchPackage() {
	releasePackage core pkg-any-a any
	releasePackage extra pkg-any-a any
	"${curdir}"/../../db-update
	"${curdir}"/../../db-remove core i686 pkg-any-a
	"${curdir}"/../../db-remove extra x86_64 pkg-any-a

	pushd "${TMP}/svn-packages-copy/pkg-any-a/trunk/" >/dev/null
	sed 's/pkgrel=1/pkgrel=2/g' -i PKGBUILD
	arch_svn commit -q -m"update pkg to pkgrel=2" >/dev/null
	popd >/dev/null

	releasePackage testing pkg-any-a any
	"${curdir}"/../../db-update

	"${curdir}"/../../testing2x pkg-any-a

	checkPackage core pkg-any-a-1-2-any.pkg.tar.xz x86_64
	checkPackage extra pkg-any-a-1-2-any.pkg.tar.xz i686
	checkRemovedAnyPackage testing pkg-any-a
}


testMoveChangedSplitDebugPackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-debug-a' 'pkg-debug-b')
	local arch

	for arch in ${arches[@]}; do
		releasePackage core pkg-debug-a ${arch}
		releasePackage core pkg-debug-b ${arch} pkg-debug-b1
	done
	releasePackage extra pkg-debug-b any pkg-debug-b2

	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/pkg-debug-a/trunk/" >/dev/null
	sed "s/pkgrel=1/pkgrel=2/g" -i PKGBUILD
	arch_svn commit -q -m"bump pkgrel=2" >/dev/null
	popd >/dev/null

	pushd "${TMP}/svn-packages-copy/pkg-debug-b/trunk/" >/dev/null
	sed "s/pkgrel=1/pkgrel=2/g;s/pkgname=('pkg-debug-b1' 'pkg-debug-b2')/pkgname='pkg-debug-b2'/g" -i PKGBUILD
	arch_svn commit -q -m"remove pkg-debug-b1; pkgrel=2" >/dev/null
	popd >/dev/null

	for arch in ${arches[@]}; do
		releasePackage testing pkg-debug-a ${arch}
	done
	releasePackage testing pkg-debug-b any pkg-debug-b2

	"${curdir}"/../../db-update

	"${curdir}"/../../testing2x pkg-debug-a pkg-debug-b2

	for arch in ${arches[@]}; do
		checkPackage core pkg-debug-a-1-2-${arch}.pkg.tar.xz ${arch}
		checkPackage core-${DEBUGSUFFIX} pkg-debug-a-${DEBUGSUFFIX}-1-2-${arch}.pkg.tar.xz ${arch}
		checkRemovedPackage testing pkg-debug-a ${arch}
		checkRemovedPackage testing-${DEBUGSUFFIX} pkg-debug-a-${DEBUGSUFFIX} ${arch}

		checkRemovedPackage core pkg-debug-b1 ${arch}
		checkRemovedPackage core-${DEBUGSUFFIX} pkg-debug-b1-${DEBUGSUFFIX} ${arch}
		checkRemovedPackage testing pkg-debug-b1 ${arch}
		checkRemovedPackage testing-${DEBUGSUFFIX} pkg-debug-b2-${DEBUGSUFFIX} ${arch}
	done
	checkAnyPackage extra pkg-debug-b2-1-2-any.pkg.tar.xz
	checkRemovedAnyPackage testing pkg-debug-b2
}

. "${curdir}/../lib/shunit2"
