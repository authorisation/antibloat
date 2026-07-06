# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Intel Processor Trace (PT) decoder library"
HOMEPAGE="https://github.com/intel/libipt"
SRC_URI="https://github.com/intel/libipt/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0/$(ver_cut 1)"
KEYWORDS="amd64 ~x86"

IUSE="doc ptdump ptseg pttc ptxed sideband +threads static-libs test"
RESTRICT="!test? ( test )"

RDEPEND="ptxed? ( dev-libs/intel-xed )"
DEPEND="${RDEPEND}"
BDEPEND="doc? ( app-text/pandoc )"

PATCHES=(
	"${FILESDIR}"/${P}-ptxed-drop-xed_decoded_inst_get_byte.patch
)

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=$(usex static-libs OFF ON)
		-DFEATURE_THREADS=$(usex threads)
		-DMAN=$(usex doc)
		-DPTDUMP=$(usex ptdump)
		-DPTSEG=$(usex ptseg)
		-DPTTC=$(usex pttc)
		-DPTXED=$(usex ptxed)
		-DSIDEBAND=$(usex sideband)
		-DPTUNIT=$(usex test)
		# never turn warnings into hard errors on user systems
		-DDEVBUILD=OFF
	)

	if use ptxed; then
		: "${XED_ROOT:=${ESYSROOT}/usr}"
		mycmakeargs+=(
			-DFEATURE_ELF=ON
			-DXED_INCLUDE="${XED_ROOT}/include"
			-DXED_LIBDIR="${XED_ROOT}/$(get_libdir)"
		)
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install
	local tool
	for tool in ptdump ptseg pttc ptxed; do
		if use "${tool}" && [[ -x "${BUILD_DIR}/bin/${tool}" ]]; then
			dobin "${BUILD_DIR}/bin/${tool}"
		fi
	done

	dodoc README CONTRIBUTING
	use doc && dodoc -r doc/.
}
