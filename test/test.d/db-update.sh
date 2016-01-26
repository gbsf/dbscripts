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
			releasePackage extra ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			checkPackage extra ${pkgbase}-1-1-${arch}.pkg.tar.xz ${arch}
		done
	done
}

testAddSingleSimplePackage() {
	releasePackage extra 'pkg-simple-a' 'i686'
	"${curdir}"/../../db-update
	checkPackage extra 'pkg-simple-a-1-1-i686.pkg.tar.xz' 'i686'
}

testAddSingleEpochPackage() {
	releasePackage extra 'pkg-simple-epoch' 'i686'
	"${curdir}"/../../db-update
	checkPackage extra 'pkg-simple-epoch-1:1-1-i686.pkg.tar.xz' 'i686'
}

testAddAnyPackages() {
	local pkgs=('pkg-any-a' 'pkg-any-b')
	local pkgbase

	for pkgbase in ${pkgs[@]}; do
		releasePackage extra ${pkgbase} any
	done

	"${curdir}"/../../db-update

	for pkgbase in ${pkgs[@]}; do
		checkAnyPackage extra ${pkgbase}-1-1-any.pkg.tar.xz
	done
}

testAddSplitPackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-split-a' 'pkg-split-b')
	local pkg
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage extra ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			for pkg in "${pkgdir}/${pkgbase}"/*-1-1-${arch}${PKGEXT}; do
				checkPackage extra ${pkg##*/} ${arch}
			done
		done
	done
}

testUpdateAnyPackage() {
	releasePackage extra pkg-any-a any
	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/pkg-any-a/trunk/" >/dev/null
	sed 's/pkgrel=1/pkgrel=2/g' -i PKGBUILD
	arch_svn commit -q -m"update pkg to pkgrel=2" >/dev/null
	popd >/dev/null

	releasePackage extra pkg-any-a any
	"${curdir}"/../../db-update

	checkAnyPackage extra pkg-any-a-1-2-any.pkg.tar.xz any
}

testUpdateAnyPackageToDifferentRepositoriesAtOnce() {
	releasePackage extra pkg-any-a any

	pushd "${TMP}/svn-packages-copy/pkg-any-a/trunk/" >/dev/null
	sed 's/pkgrel=1/pkgrel=2/g' -i PKGBUILD
	arch_svn commit -q -m"update pkg to pkgrel=2" >/dev/null
	popd >/dev/null

	releasePackage testing pkg-any-a any

	"${curdir}"/../../db-update

	checkAnyPackage extra pkg-any-a-1-1-any.pkg.tar.xz any
	checkAnyPackage testing pkg-any-a-1-2-any.pkg.tar.xz any
}

testUpdateSameAnyPackageToSameRepository() {
	releasePackage extra pkg-any-a any
	"${curdir}"/../../db-update
	checkAnyPackage extra pkg-any-a-1-1-any.pkg.tar.xz any

	releasePackage extra pkg-any-a any
	"${curdir}"/../../db-update >/dev/null 2>&1 && (fail 'Adding an existing package to the same repository should fail'; return 1)
}

testUpdateSameAnyPackageToDifferentRepositories() {
	releasePackage extra pkg-any-a any
	"${curdir}"/../../db-update
	checkAnyPackage extra pkg-any-a-1-1-any.pkg.tar.xz any

	releasePackage testing pkg-any-a any
	"${curdir}"/../../db-update >/dev/null 2>&1 && (fail 'Adding an existing package to another repository should fail'; return 1)

	local arch
	for arch in "${ARCHES[@]}"; do
		( [ -r "${FTP_BASE}/testing/os/${arch}/testing${DBEXT%.tar.*}" ] \
			&& bsdtar -xf "${FTP_BASE}/testing/os/${arch}/testing${DBEXT%.tar.*}" -O | grep -q ${pkgbase}) \
			&& fail "${pkgbase} should not be in testing/os/${arch}/testing${DBEXT%.tar.*}"
	done
}

testAddIncompleteSplitPackage() {
	local arches=('i686' 'x86_64')
	local repo='extra'
	local pkgbase='pkg-split-a'
	local arch

	for arch in ${arches[@]}; do
		releasePackage ${repo} ${pkgbase} ${arch}
	done

	# remove a split package to make db-update ignore it
	rm "${STAGING}"/extra/${pkgbase}1-*

	"${curdir}"/../../db-update

	for arch in ${arches[@]}; do
		checkRemovedPackage extra ${pkgbase} $arch
	done
}

testUpdateRemoveSplitPackage() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-split-a'
	local arch

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch}
	done

	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/pkg-split-a/trunk/" >/dev/null
	sed "s/pkgrel=1/pkgrel=2/g;s/pkgname=('pkg-split-a1' 'pkg-split-a2')/pkgname='pkg-split-a1'/g" -i PKGBUILD
	arch_svn commit -q -m"remove pkg-split-a2; pkgrel=2" >/dev/null
	popd >/dev/null

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch}
	done

	"${curdir}"/../../db-update

	for arch in ${arches[@]}; do
		checkPackage extra ${pkgbase}1-1-2-${arch}.pkg.tar.xz ${arch}
		checkRemovedPackage extra ${pkgbase}2-1-2-${arch}.pkg.tar.xz ${arch}
	done
}

testUpdateRemoveAnySplitPackage() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-split-c'
	local arch

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch} ${pkgbase}1
	done
	releasePackage extra ${pkgbase} any ${pkgbase}2

	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/pkg-split-c/trunk/" >/dev/null
	sed "s/pkgrel=1/pkgrel=2/g;s/pkgname=('pkg-split-c1' 'pkg-split-c2')/pkgname='pkg-split-c1'/g" -i PKGBUILD
	arch_svn commit -q -m"remove pkg-split-c2; pkgrel=2" >/dev/null
	popd >/dev/null

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch} ${pkgbase}1
	done

	"${curdir}"/../../db-update

	for arch in ${arches[@]}; do
		checkPackage extra ${pkgbase}1-1-2-${arch}.pkg.tar.xz ${arch}
	done
	checkRemovedAnyPackage extra ${pkgbase}2-1-1-any.pkg.tar.xz
}

testUnknownRepo() {
	mkdir "${STAGING}/unknown/"
	releasePackage extra 'pkg-simple-a' 'i686'
	releasePackage unknown 'pkg-simple-b' 'i686'
	"${curdir}"/../../db-update
	checkPackage extra 'pkg-simple-a-1-1-i686.pkg.tar.xz' 'i686'
	[ -e "${FTP_BASE}/unknown" ] && fail "db-update pushed a package into an unknown repository"
	rm -rf "${STAGING}/unknown/"
}

. "${curdir}/../lib/shunit2"
