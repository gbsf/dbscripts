load ../lib/common

@test "move single packages" {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		releasePackage testing ${pkgbase}
	done

	db-update

	db-move testing extra all pkg-simple-a

	checkRemovedPackage testing pkg-simple-a
	checkPackage extra pkg-simple-a
	checkPackage testing pkg-simple-b
}

@test "move multiple packages" {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		releasePackage testing ${pkgbase}
	done

	db-update

	db-move testing extra all pkg-simple-a pkg-simple-b

	for pkgbase in ${pkgs[@]}; do
		checkRemovedPackage testing ${pkgbase}
		checkPackage extra ${pkgbase}
	done
}

@test "move epoch packages" {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-epoch')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		releasePackage testing ${pkgbase}
	done

	db-update

	db-move testing extra all pkg-simple-epoch

	checkRemovedPackage testing pkg-simple-epoch
	checkPackage extra pkg-simple-epoch
}

@test "move any packages" {
	local pkgs=('pkg-any-a' 'pkg-any-b')
	local pkgbase

	for pkgbase in ${pkgs[@]}; do
		releasePackage testing ${pkgbase}
	done

	db-update
	db-move testing extra all pkg-any-a

	checkPackage extra pkg-any-a
	checkRemovedPackage testing pkg-any-a
	checkPackage testing pkg-any-b
}

@test "move split packages" {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-split-a' 'pkg-split-b')
	local pkg
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		releasePackage testing ${pkgbase}
	done

	db-update
	db-move testing extra all pkg-split-a

	checkPackage extra pkg-split-a
	checkPackage testing pkg-split-b
}
