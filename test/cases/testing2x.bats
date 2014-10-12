load ../lib/common

@test "move any package" {
	releasePackage core pkg-any-a
	db-update

	updatePackage pkg-any-a

	releasePackage testing pkg-any-a
	db-update

	testing2x pkg-any-a

	checkPackage core pkg-any-a
	checkRemovedPackage testing pkg-any-a
}

testTesting2xMultiArchPackage() {
	releasePackage core pkg-any-a any
	releasePackage extra pkg-any-a any
	db-update
	db-remove core i686 pkg-any-a
	db-remove extra x86_64 pkg-any-a

	pushd "${TMP}/svn-packages-copy/pkg-any-a/trunk/" >/dev/null
	sed 's/pkgrel=1/pkgrel=2/g' -i PKGBUILD
	arch_svn commit -q -m"update pkg to pkgrel=2" >/dev/null
	__buildPackage "${pkgdir}/pkg-any-a/"
	popd >/dev/null

	releasePackage testing pkg-any-a any
	db-update
	rm -f "${pkgdir}/pkg-any-a/pkg-any-a-1-2-any.pkg.tar.xz"

	testing2x pkg-any-a

	checkPackage core pkg-any-a-1-2-any.pkg.tar.xz x86_64
	checkPackage extra pkg-any-a-1-2-any.pkg.tar.xz i686
	checkRemovedPackage testing pkg-any-a
}
