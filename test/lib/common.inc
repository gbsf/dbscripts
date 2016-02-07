set -E

lib_dir="$(readlink -e $(dirname ${BASH_SOURCE[0]}))"

# Turn on debugging
export DBSCRIPTS_DEBUG=1

. "${lib_dir}/../../config"
# override the default TMPDIR
TMPDIR="$(mktemp -d /tmp/${0##*/}.XXXXXXXXXX)"
. "${lib_dir}/../../db-functions"

signpkg() {
	if [[ -r '/etc/makepkg.conf' ]]; then
		source '/etc/makepkg.conf'
	else
		die '/etc/makepkg.conf not found!'
	fi
	if [[ -r ~/.makepkg.conf ]]; then
		. ~/.makepkg.conf
	fi
	if [[ -n $GPGKEY ]]; then
		SIGNWITHKEY="-u ${GPGKEY}"
	fi
	gpg --batch -q --detach-sign --use-agent --no-armor ${SIGNWITHKEY} ${@} || die
}

oneTimeSetUp() {
	local p
	local d
	local a
	local pkgname
	local pkgarch
	local pkgversion
	local build
	local arches=()
	pkgdir="$(mktemp -d /tmp/${0##*/}.XXXXXXXXXX)"
	cp -Lr ${lib_dir}/../packages/* "${pkgdir}"
	msg 'Building packages...'
	for d in "${pkgdir}"/*; do
		pushd $d >/dev/null
		pkgname=() # reset variable to not upset subshell
		pkgname=($(. PKGBUILD; echo ${pkgname[@]}))

		build=true
		for p in ${pkgname[@]}; do
			pkgarch=($(. PKGBUILD; get_arch ${p}))
			arches+=(${pkgarch[@]})
			pkgversion=$(. PKGBUILD; get_full_version ${p})
			for a in ${pkgarch[@]}; do
				[ ! -f ${p}-${pkgversion}-${a}${PKGEXT} ] && build=false
			done
		done

		if ! ${build}; then
			# check if all packages have any arch
			pkgarch=($(dedup_array ${arches[@]} any))
			if [[ ${#pkgarch[@]} == 1 ]]; then
				sudo extra-x86_64-build || die 'extra-x86_64-build failed'
				sed 's/pkgrel=1/pkgrel=2/g' -i PKGBUILD
				sudo extra-x86_64-build || die 'extra-x86_64-build failed'
			else
				# remove any
				pkgarch=($(uniq_array ${pkgarch[@]} any))
				for a in ${pkgarch[@]}; do
					sudo extra-${a}-build || die "extra-${a}-build failed"
				done
				sed 's/pkgrel=1/pkgrel=2/g' -i PKGBUILD
				for a in ${pkgarch[@]}; do
					sudo extra-${a}-build || die "extra-${a}-build failed"
				done
			fi

			cp *${PKGEXT} ${lib_dir}/../packages/${d##*/}
		fi

		if ${REQUIRE_SIGNATURE}; then
			for pkg in *${PKGEXT}; do
				if [ ! -f "${pkg}.sig" ] || ! pacman-key -v "${pkg}.sig" >/dev/null 2>&1; then
					rm -f "${pkg}.sig"
					signpkg ${pkg}
					cp ${pkg}.sig ${lib_dir}/../packages/${d##*/}
				fi
			done

		fi

		popd >/dev/null
	done
}

oneTimeTearDown() {
	rm -rf "${pkgdir}"
}

setUp() {
	local p
	local pkg
	local r
	local a

	[ -f "${lib_dir}/../../config.local" ] && die "${lib_dir}/../../config.local exists"
	TMP="$(mktemp -d /tmp/${0##*/}.XXXXXXXXXX)"

	PKGREPOS=('core' 'extra' 'testing')
	PKGPOOL='pool/packages'
	mkdir -p "${TMP}/"{ftp,tmp,staging,{package,source}-cleanup,svn-packages-{copy,repo}}

	for r in "${PKGREPOS[@]}" "${PKGREPOS[@]/%/-${DEBUGSUFFIX}}"; do
		mkdir -p "${TMP}/staging/${r}"
		for a in ${ARCHES[@]}; do
			mkdir -p "${TMP}/ftp/${r}/os/${a}"
		done
	done
	mkdir -p "${TMP}/ftp/${PKGPOOL}"
	mkdir -p "${TMP}/ftp/${SRCPOOL}"
	mkdir -p "${TMP}/history-repo"
	git init -q "${TMP}/history-repo"

	svnadmin create "${TMP}/svn-packages-repo"
	arch_svn checkout -q "file://${TMP}/svn-packages-repo" "${TMP}/svn-packages-copy"

	for p in "${lib_dir}"/../packages/*; do
		pkg=${p##*/}
		mkdir -p "${TMP}/svn-packages-copy/${pkg}"/{trunk,repos}
		# copy all but packages
		cp "${p}"/!(*${PKGEXT}?(.sig)) "${TMP}/svn-packages-copy"/${pkg}/trunk/
		arch_svn add -q "${TMP}/svn-packages-copy"/${pkg}
		arch_svn commit -q -m"initial commit of ${pkg}" "${TMP}/svn-packages-copy"
	done

	cat <<eot > "${lib_dir}/../../config.local"
	FTP_BASE="${TMP}/ftp"
	SVNREPO="file://${TMP}/svn-packages-repo"
	HISTORYREPO="${TMP}/history-repo"
	PKGREPOS=(${PKGREPOS[@]})
	PKGPOOL="${PKGPOOL}"
	TESTING_REPO='testing'
	STABLE_REPOS=('core' 'extra')
	CLEANUP_DESTDIR="${TMP}/package-cleanup"
	SOURCE_CLEANUP_DESTDIR="${TMP}/source-cleanup"
	STAGING="${TMP}/staging"
	TMPDIR="${TMP}/tmp"
	CLEANUP_DRYRUN=false
	SOURCE_CLEANUP_DRYRUN=false
	REQUIRE_SIGNATURE=true
eot
	. "${lib_dir}/../../config"
}

tearDown() {
	rm -rf "${TMP}"
	rm -f "${lib_dir}/../../config.local"
	echo
}

archreleasePackage() {
	local pkgbase=$1
	pushd "${TMP}/svn-packages-copy"/${pkgbase}/trunk/ >/dev/null

	"${lib_dir}"/../../archrelease >/dev/null 2>&1

	popd >/dev/null
}

releasePackage() {
	local repo=$1
	local pkgbase=$2
	local arch=$3
	local singlepkg=$4
	local a
	local p
	local pkgver
	local pkgname
	local arches
	local -a to_copy

	archreleasePackage "${pkgbase}"
	pushd "${TMP}/svn-packages-copy"/${pkgbase}/trunk/ >/dev/null
	pkgver=$(. PKGBUILD; get_full_version ${pkgname})
	pkgname=($(. PKGBUILD; echo ${pkgname[@]}))

	popd >/dev/null

	if [ -n "${singlepkg}" ]; then
		if in_array ${singlepkg} ${pkgname[@]}; then
			pkgname=(${singlepkg})
		else
			error "Package ${singlepkg} is not part of ${pkgbase}"
			return 1
		fi
	fi

	to_copy=()
	for name in ${pkgname[@]}; do
		to_copy+=("${pkgdir}"/${pkgbase}/${name}-${pkgver}-${arch}${PKGEXT})
		[ -f "${pkgdir}"/${pkgbase}/${name}-${pkgver}-${arch}${PKGEXT}.sig ] &&
			to_copy+=("${pkgdir}"/${pkgbase}/${name}-${pkgver}-${arch}${PKGEXT}.sig)
	done

	cp "${to_copy[@]}" "${STAGING}"/${repo}/

	to_copy=()
	for name in ${pkgname[@]}; do
		if [ -f "${pkgdir}"/${pkgbase}/${name}-${DEBUGSUFFIX}-${pkgver}-${arch}${PKGEXT} ]; then
			to_copy+=("${pkgdir}"/${pkgbase}/${name}-${DEBUGSUFFIX}-${pkgver}-${arch}${PKGEXT})
			[ -f "${pkgdir}"/${pkgbase}/${name}-${DEBUGSUFFIX}-${pkgver}-${arch}${PKGEXT}.sig ] &&
				to_copy+=("${pkgdir}"/${pkgbase}/${name}-${DEBUGSUFFIX}-${pkgver}-${arch}${PKGEXT}.sig)
		fi
	done

	[[ ${#to_copy[@]} > 0 ]] && cp "${to_copy[@]}" "${STAGING}"/${repo}-${DEBUGSUFFIX}/

	if [[ $arch == "any" ]]; then
		arches=("${ARCHES[@]}")
	else
		arches=($arch)
	fi

	for _arch in "${arches[@]}"; do
		for single_name in "${pkgname[@]}"; do
			pkgfile=("${STAGING}/${repo}/"${single_name}-${pkgver}-${arch}${PKGEXT})
			pkgfile=${pkgfile[0]##*/}
			mkdir -p "${STAGING}/${repo}/${_arch}"
			ln -sr "${STAGING}/${repo}/${pkgfile}" "${STAGING}/${repo}/${_arch}/${pkgfile}"

			debugfile=("${STAGING}/${repo}-${DEBUGSUFFIX}/"${single_name}-${DEBUGSUFFIX}-${pkgver}-${arch}${PKGEXT})
			if [ -f "${debugfile[0]}" ]; then
				debugfile=${debugfile[0]##*/}
				mkdir -p "${STAGING}/${repo}-${DEBUGSUFFIX}/${_arch}"
				ln -sr "${STAGING}/${repo}-${DEBUGSUFFIX}/${debugfile}" \
					"${STAGING}/${repo}-${DEBUGSUFFIX}/${_arch}/${debugfile}"
			fi
		done
	done
}

checkAnyPackageDB() {
	local repo=$1
	local pkg=$2
	local arch
	local db

	[ -r "${FTP_BASE}/${PKGPOOL}/${pkg}" ] || fail "${PKGPOOL}/${pkg} not found"
	if ${REQUIRE_SIGNATURE}; then
		[ -r "${FTP_BASE}/${PKGPOOL}/${pkg}.sig" ] || fail "${PKGPOOL}/${pkg}.sig not found"
	fi

	for arch in "${ARCHES[@]}"; do
		[ -L "${FTP_BASE}/${repo}/os/${arch}/${pkg}" ] || fail "${repo}/os/${arch}/${pkg} is not a symlink"
		[ "$(readlink -e "${FTP_BASE}/${repo}/os/${arch}/${pkg}")" == "${FTP_BASE}/${PKGPOOL}/${pkg}" ] \
			|| fail "${repo}/os/${arch}/${pkg} does not link to ${PKGPOOL}/${pkg}"

		if ${REQUIRE_SIGNATURE}; then
			[ -L "${FTP_BASE}/${repo}/os/${arch}/${pkg}.sig" ] || fail "${repo}/os/${arch}/${pkg}.sig is not a symlink"
			[ "$(readlink -e "${FTP_BASE}/${repo}/os/${arch}/${pkg}.sig")" == "${FTP_BASE}/${PKGPOOL}/${pkg}.sig" ] \
				|| fail "${repo}/os/${arch}/${pkg}.sig does not link to ${PKGPOOL}/${pkg}.sig"
		fi

		for db in ${DBEXT} ${FILESEXT}; do
			( [ -r "${FTP_BASE}/${repo}/os/${arch}/${repo}${db%.tar.*}" ] \
				&& bsdtar -xf "${FTP_BASE}/${repo}/os/${arch}/${repo}${db%.tar.*}" -O | grep -q ${pkg}) \
				|| fail "${pkg} not in ${repo}/os/${arch}/${repo}${db%.tar.*}"
		done
	done
	[ -r "${STAGING}"/${repo}/${pkg} ] && fail "${repo}/${pkg} found in staging dir"
	[ -r "${STAGING}"/${repo}/${pkg}.sig ] && fail "${repo}/${pkg}.sig found in staging dir"
}

checkAnyPackage() {
	local repo=$1
	local pkg=$2

	checkAnyPackageDB $repo $pkg

# TODO: remove? should not be needed anymore since we don't modify svn in dbscripts
	#local pkgbase=$(getpkgbase "${FTP_BASE}/${PKGPOOL}/${pkg}")
	#arch_svn up -q "${TMP}/svn-packages-copy/${pkgbase}"
	#[ -d "${TMP}/svn-packages-copy/${pkgbase}/repos/${repo}-any" ] \
		#|| fail "svn-packages-copy/${pkgbase}/repos/${repo}-any does not exist"
}

checkPackageDB() {
	local repo=$1
	local pkg=$2
	local arch=$3
	local db

	[ -r "${FTP_BASE}/${PKGPOOL}/${pkg}" ] || fail "${PKGPOOL}/${pkg} not found"
	[ -L "${FTP_BASE}/${repo}/os/${arch}/${pkg}" ] || fail "${repo}/os/${arch}/${pkg} not a symlink"
	[ -r "${STAGING}"/${repo}/${pkg} ] && fail "${repo}/${pkg} found in staging dir"

	[ "$(readlink -e "${FTP_BASE}/${repo}/os/${arch}/${pkg}")" == "${FTP_BASE}/${PKGPOOL}/${pkg}" ] \
		|| fail "${repo}/os/${arch}/${pkg} does not link to ${PKGPOOL}/${pkg}"

	if ${REQUIRE_SIGNATURE}; then
		[ -r "${FTP_BASE}/${PKGPOOL}/${pkg}.sig" ] || fail "${PKGPOOL}/${pkg}.sig not found"
		[ -L "${FTP_BASE}/${repo}/os/${arch}/${pkg}.sig" ] || fail "${repo}/os/${arch}/${pkg}.sig is not a symlink"
		[ -r "${STAGING}"/${repo}/${pkg}.sig ] && fail "${repo}/${pkg}.sig found in staging dir"

		[ "$(readlink -e "${FTP_BASE}/${repo}/os/${arch}/${pkg}.sig")" == "${FTP_BASE}/${PKGPOOL}/${pkg}.sig" ] \
			|| fail "${repo}/os/${arch}/${pkg}.sig does not link to ${PKGPOOL}/${pkg}.sig"
	fi

	for db in ${DBEXT} ${FILESEXT}; do
		( [ -r "${FTP_BASE}/${repo}/os/${arch}/${repo}${db%.tar.*}" ] \
			&& bsdtar -xf "${FTP_BASE}/${repo}/os/${arch}/${repo}${db%.tar.*}" -O | grep -q ${pkg}) \
			|| fail "${pkg} not in ${repo}/os/${arch}/${repo}${db%.tar.*}"
	done
}

checkPackage() {
	local repo=$1
	local pkg=$2
	local arch=$3

	checkPackageDB $repo $pkg $arch

# TODO: remove? should not be needed anymore since we don't modify svn in dbscripts
	#local pkgbase=$(getpkgbase "${FTP_BASE}/${PKGPOOL}/${pkg}")
	#arch_svn up -q "${TMP}/svn-packages-copy/${pkgbase}"
	#[ -d "${TMP}/svn-packages-copy/${pkgbase}/repos/${repo}-${arch}" ] \
		#|| fail "svn-packages-copy/${pkgbase}/repos/${repo}-${arch} does not exist"
}

checkRemovedPackageDB() {
	local repo=$1
	local pkgbase=$2
	local arch=$3
	local db

	for db in ${DBEXT} ${FILESEXT}; do
		( [ -r "${FTP_BASE}/${repo}/os/${arch}/${repo}${db%.tar.*}" ] \
			&& bsdtar -xf "${FTP_BASE}/${repo}/os/${arch}/${repo}${db%.tar.*}" -O | grep -q ${pkgbase}) \
			&& fail "${pkgbase} should not be in ${repo}/os/${arch}/${repo}${db%.tar.*}"
	done
}

checkRemovedPackage() {
	local repo=$1
	local pkgbase=$2
	local arch=$3

	checkRemovedPackageDB $repo $pkgbase $arch

# TODO: remove? should not be needed anymore since we don't modify svn in dbscripts
	#arch_svn up -q "${TMP}/svn-packages-copy/${pkgbase}"
	#[ -d "${TMP}/svn-packages-copy/${pkgbase}/repos/${repo}-${arch}" ] \
		#&& fail "svn-packages-copy/${pkgbase}/repos/${repo}-${arch} should not exist"
}

checkRemovedAnyPackageDB() {
	local repo=$1
	local pkgbase=$2
	local arch
	local db

	for db in ${DBEXT} ${FILESEXT}; do
		for arch in "${ARCHES[@]}"; do
			( [ -r "${FTP_BASE}/${repo}/os/${arch}/${repo}${db%.tar.*}" ] \
				&& bsdtar -xf "${FTP_BASE}/${repo}/os/${arch}/${repo}${db%.tar.*}" -O | grep -q ${pkgbase}) \
				&& fail "${pkgbase} should not be in ${repo}/os/${arch}/${repo}${db%.tar.*}"
		done
	done
}

checkRemovedAnyPackage() {
	local repo=$1
	local pkgbase=$2

	checkRemovedAnyPackageDB $repo $pkgbase

# TODO: remove? should not be needed anymore since we don't modify svn in dbscripts
	#arch_svn up -q "${TMP}/svn-packages-copy/${pkgbase}"
	#[ -d "${TMP}/svn-packages-copy/${pkgbase}/repos/${repo}-any" ] \
		#&& fail "svn-packages-copy/${pkgbase}/repos/${repo}-any should not exist"
}

# vim: ft=sh:
