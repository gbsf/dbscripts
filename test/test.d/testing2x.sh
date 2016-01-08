#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testTesting2xAnyPackage() {
	releasePackage core pkg-any-a any
	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/pkg-any-a/trunk/" >/dev/null
	sed 's/pkgrel=1/pkgrel=2/g' -i PKGBUILD
	arch_svn commit -q -m"update pkg to pkgrel=2" >/dev/null
	# TODO: move this to the initial build phase
	sudo chronic extra-i686-build
	mv pkg-any-a-1-2-any.pkg.tar.xz "${pkgdir}/pkg-any-a/"
	popd >/dev/null

	releasePackage testing pkg-any-a any
	"${curdir}"/../../db-update
	rm -f "${pkgdir}/pkg-any-a/pkg-any-a-1-2-any.pkg.tar.xz"

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
	# TODO: move this to the initial build phase
	sudo chronic extra-i686-build
	mv pkg-any-a-1-2-any.pkg.tar.xz "${pkgdir}/pkg-any-a/"
	popd >/dev/null

	releasePackage testing pkg-any-a any
	"${curdir}"/../../db-update
	rm -f "${pkgdir}/pkg-any-a/pkg-any-a-1-2-any.pkg.tar.xz"

	"${curdir}"/../../testing2x pkg-any-a

	checkPackage core pkg-any-a-1-2-any.pkg.tar.xz x86_64
	checkPackage extra pkg-any-a-1-2-any.pkg.tar.xz i686
	checkRemovedAnyPackage testing pkg-any-a
}

. "${curdir}/../lib/shunit2"
