#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testCleanupSimplePackages() {
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

	for arch in ${arches[@]}; do
		"${curdir}"/../../db-remove extra ${arch} pkg-simple-a
	done

	"${curdir}"/../../cron-jobs/ftpdir-cleanup >/dev/null

	for arch in ${arches[@]}; do
		local pkg1="pkg-simple-a-1-1-${arch}.pkg.tar.xz"
		checkRemovedPackage extra 'pkg-simple-a' ${arch}
		[ -f "${FTP_BASE}/${PKGPOOL}/${pkg1}" ] && fail "${PKGPOOL}/${pkg1} found"
		[ -f "${FTP_BASE}/${repo}/os/${arch}/${pkg1}" ] && fail "${repo}/os/${arch}/${pkg1} found"

		local pkg2="pkg-simple-b-1-1-${arch}.pkg.tar.xz"
		checkPackage extra ${pkg2} ${arch}
	done
}

testCleanupEpochPackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-epoch')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage extra ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	for arch in ${arches[@]}; do
		"${curdir}"/../../db-remove extra ${arch} pkg-simple-epoch
	done

	"${curdir}"/../../cron-jobs/ftpdir-cleanup >/dev/null

	for arch in ${arches[@]}; do
		local pkg1="pkg-simple-epoch-1:1-1-${arch}.pkg.tar.xz"
		checkRemovedPackage extra 'pkg-simple-epoch' ${arch}
		[ -f "${FTP_BASE}/${PKGPOOL}/${pkg1}" ] && fail "${PKGPOOL}/${pkg1} found"
		[ -f "${FTP_BASE}/${repo}/os/${arch}/${pkg1}" ] && fail "${repo}/os/${arch}/${pkg1} found"
	done
}

testCleanupAnyPackages() {
	local pkgs=('pkg-any-a' 'pkg-any-b')
	local pkgbase
	local arch='any'

	for pkgbase in ${pkgs[@]}; do
		releasePackage extra ${pkgbase} any
	done

	"${curdir}"/../../db-update
	"${curdir}"/../../db-remove extra all pkg-any-a
	"${curdir}"/../../cron-jobs/ftpdir-cleanup >/dev/null

	local pkg1='pkg-any-a-1-1-any.pkg.tar.xz'
	checkRemovedAnyPackage extra 'pkg-any-a'
	[ -f "${FTP_BASE}/${PKGPOOL}/${pkg1}" ] && fail "${PKGPOOL}/${pkg1} found"
	[ -f "${FTP_BASE}/${repo}/os/${arch}/${pkg1}" ] && fail "${repo}/os/${arch}/${pkg1} found"

	local pkg2="pkg-any-b-1-1-${arch}.pkg.tar.xz"
	checkAnyPackage extra ${pkg2}
}

testCleanupSplitPackages() {
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

	for arch in ${arches[@]}; do
		"${curdir}"/../../db-remove extra ${arch} pkg-split-a{1,2}
	done

	"${curdir}"/../../cron-jobs/ftpdir-cleanup >/dev/null

	for arch in ${arches[@]}; do
		for pkg in "${pkgdir}/${pkgs[0]}"/*-${arch}${PKGEXT}; do
			checkRemovedPackage extra ${pkgs[0]} ${arch}
			[ -f "${FTP_BASE}/${PKGPOOL}/${pkg}" ] && fail "${PKGPOOL}/${pkg} found"
			[ -f "${FTP_BASE}/${repo}/os/${arch}/${pkg}" ] && fail "${repo}/os/${arch}/${pkg} found"
		done

		for pkg in "${pkgdir}/${pkgs[1]}"/*-1-1-${arch}${PKGEXT}; do
			checkPackage extra ${pkg##*/} ${arch}
		done
	done
}

testCleanupDebugPackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-debug-a')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage extra ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	for arch in ${arches[@]}; do
		"${curdir}"/../../db-remove extra ${arch} pkg-debug-a
	done

	"${curdir}"/../../cron-jobs/ftpdir-cleanup >/dev/null

	for arch in ${arches[@]}; do
		local pkg1="pkg-debug-a-1-1-${arch}.pkg.tar.xz"
		checkRemovedPackage extra 'pkg-debug-a' ${arch}
		[ -f "${FTP_BASE}/${PKGPOOL}/${pkg1}" ] && fail "${PKGPOOL}/${pkg1} found"
		[ -f "${FTP_BASE}/${repo}/os/${arch}/${pkg1}" ] && fail "${repo}/os/${arch}/${pkg1} found"

		local pkg2="pkg-debug-a-debug-1-1-${arch}.pkg.tar.xz"
		checkRemovedPackage extra ${pkg2} ${arch}
		[ -f "${FTP_BASE}/${PKGPOOL}/${pkg2}" ] && fail "${PKGPOOL}/${pkg2} found"
		[ -f "${FTP_BASE}/${repo}-${DEBUGSUFFIX}/os/${arch}/${pkg2}" ] && fail "${repo}/os/${arch}/${pkg2} found"
	done
}

. "${curdir}/../lib/shunit2"
