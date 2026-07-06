# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )
inherit python-any-r1 toolchain-funcs multilib multiprocessing

# xed has no build system of its own, mbuild based
MBUILD_PV="2026.05.19"

DESCRIPTION="Intel X86 Encoder Decoder (libxed)"
HOMEPAGE="https://github.com/intelxed/xed"
SRC_URI="
	https://github.com/intelxed/xed/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/intelxed/mbuild/archive/refs/tags/v${MBUILD_PV}.tar.gz -> mbuild-${MBUILD_PV}.tar.gz
"
S="${WORKDIR}/xed-${PV}"

LICENSE="Apache-2.0"
# libxed has an unversioned SONAME
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE="static-libs"

BDEPEND="${PYTHON_DEPS}"

xed_setup_mbuild() {
	ln -snf "${WORKDIR}/mbuild-${MBUILD_PV}" "${WORKDIR}/mbuild" || die
}

xed_mfile_args() {
	local args=(
		--jobs="$(makeopts_jobs)"
		--opt=noopt
		--no-werror
		--cc="$(tc-getCC)"
		--cxx="$(tc-getCXX)"
		--strip="$(type -P true)"
	)
	[[ -n ${CFLAGS} ]] && args+=( --extra-ccflags="${CFLAGS}" )
	[[ -n ${LDFLAGS} ]] && args+=( --extra-linkflags="${LDFLAGS}" )
	printf '%s\n' "${args[@]}"
}

pkg_setup() {
	python-any-r1_pkg_setup
}

src_prepare() {
	default
	xed_setup_mbuild
}

src_compile() {
	local -a common
	readarray -t common < <(xed_mfile_args)

	"${EPYTHON}" mfile.py --shared "${common[@]}" || die "libxed shared build failed"

	if use static-libs; then
		"${EPYTHON}" mfile.py --static --build-dir=obj-static "${common[@]}" \
			|| die "libxed static build failed"
	fi
}

src_install() {
	local -a common
	readarray -t common < <(xed_mfile_args)

	"${EPYTHON}" mfile.py install --shared "${common[@]}" \
		--prefix="${ED}/usr" --prefix-lib-dir="$(get_libdir)" \
		|| die "libxed shared install failed"

	if use static-libs; then
		"${EPYTHON}" mfile.py install --static --build-dir=obj-static "${common[@]}" \
			--prefix="${ED}/usr" --prefix-lib-dir="$(get_libdir)" \
			|| die "libxed static install failed"
	fi

	dodoc README.md
}
