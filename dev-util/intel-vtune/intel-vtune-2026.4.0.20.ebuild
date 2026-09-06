# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Version scheme: 2026.4.0.23 == upstream 2026.4.0, build 23
EAPI=8

MODULES_OPTIONAL_IUSE="modules"
inherit desktop linux-mod-r1 toolchain-funcs unpacker xdg

MY_PV="$(ver_cut 1-3)" # 2026.4.0
MY_BUILD="$(ver_cut 4)" # 23
MY_DIR="$(ver_cut 1-2)" # 2026.4
VTUNE_ROOT="/opt/intel/oneapi/vtune/${MY_DIR}"

DESCRIPTION="Intel VTune Profiler - performance analysis for CPU, GPU and threading"
HOMEPAGE="https://www.intel.com/content/www/us/en/developer/tools/oneapi/vtune-profiler.html"
SRC_URI="https://apt.repos.intel.com/oneapi/pool/main/intel-oneapi-vtune-${MY_PV}-${MY_BUILD}_amd64.deb"
S="${WORKDIR}"

LICENSE="ISSL"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+gui"
RESTRICT="bindist mirror strip test"

RDEPEND="
	dev-libs/libffi-compat
	sys-libs/ncurses-compat
	sys-libs/libxcrypt[compat]
	sys-libs/zlib
	gui? (
		app-accessibility/at-spi2-core
		dev-libs/glib:2
		dev-libs/nss
		media-libs/alsa-lib
		x11-libs/gtk+:3
		x11-libs/libdrm
		x11-libs/libxcb
		x11-libs/libxkbcommon
		x11-libs/pango
		x11-misc/xdg-utils
	)
"
DEPEND=""
BDEPEND="gui? ( media-gfx/icoutils )"

QA_PREBUILT="opt/intel/oneapi/*"

# sep/pax/socperf/vtsspp requirements (see sepdk/src/README.txt).
CONFIG_CHECK="~MODULES ~SMP ~KPROBES ~TRACEPOINTS ~PROFILING"

pkg_setup() {
	linux-mod-r1_pkg_setup
}

src_unpack() {
	unpack_deb "${DISTDIR}/${A}"
}

src_compile() {
	use modules || return

	# sepdk ships its own driver script (build-driver) that wraps the kernel
	# Kbuild for sep5, pax, socperf and vtsspp. Drive it non-interactively
	# and point it at the configured kernel instead of /lib/modules/$(uname -r).
	cd "${S}${VTUNE_ROOT}/sepdk/src" || die

	./build-driver -ni \
		--kernel-src-dir="${KV_DIR}" \
		--kernel-version="${KV_FULL}" \
		--c-compiler="$(tc-getCC)" \
		|| die "sepdk build-driver failed"
}

src_install() {
	dodir /opt/intel/oneapi
	mv "${S}"/opt/intel/oneapi/* "${ED}"/opt/intel/oneapi/ || die

	[[ -e "${ED}/opt/intel/oneapi/vtune/latest" ]] ||
		dosym "${MY_DIR}" /opt/intel/oneapi/vtune/latest

	if use modules; then
		local ko
		while IFS= read -r -d '' ko; do
			linux_domodule "${ko}"
		done < <(find "${ED}${VTUNE_ROOT}/sepdk" -name '*.ko' -print0)

		# Don't leave build products or an unmatched-kernel .ko in /opt.
		find "${ED}${VTUNE_ROOT}/sepdk" \( -name '*.ko' -o -name '*.o' -o -name '*.mod*' -o -name '.*.cmd' \) -delete || die
	fi

	if use gui; then
		local ico="${ED}${VTUNE_ROOT}/bin64/resources/app/icons/VTune.ico"
		local icon
		mkdir -p "${T}"/icon || die
		icotool -x -o "${T}"/icon "${ico}" || die "icotool failed on VTune.ico"
		icon=$(ls "${T}"/icon/*.png | sed -E 's/.*_([0-9]+)x[0-9]+x[0-9]+\.png$/\1 &/' \
			| sort -rn | head -1 | cut -d' ' -f2)
		[[ -n ${icon} ]] || die "no PNG frames in VTune.ico"
		local size
		size=$(sed -E 's/.*_([0-9]+)x[0-9]+x[0-9]+\.png$/\1/' <<<"${icon}")
		newicon -s "${size}" "${icon}" vtune.png

		make_desktop_entry \
			"${VTUNE_ROOT}/bin64/vtune-gui %f" \
			"Intel VTune Profiler" \
			vtune \
			"Development;Profiling;" \
			"MimeType=application/x-vtune-result;\nStartupWMClass=vtune-gui\nKeywords=profiler;performance;hotspots;"
	fi

	if ! use gui; then
		rm -rf "${ED}${VTUNE_ROOT}"/bin64/vtune-gui* "${ED}${VTUNE_ROOT}"/lib64/vtune-gui* || die
	fi

	newenvd - 99intel-vtune <<-EOF
		PATH="${VTUNE_ROOT}/bin64"
	EOF
}

pkg_postinst() {
	xdg_pkg_postinst
	linux-mod-r1_pkg_postinst

	elog "VTune is installed under ${VTUNE_ROOT} (also /opt/intel/oneapi/vtune/latest)."
	elog "Run 'env-update && source /etc/profile' or 'source ${VTUNE_ROOT}/vtune-vars.sh'."
	elog
	elog "Driverless (perf-based) collection needs:"
	elog "  sysctl kernel.perf_event_paranoid=1  (0 for uncore/system-wide)"
	elog "  sysctl kernel.kptr_restrict=0"
	if use modules; then
		elog
		elog "Sampling drivers (sep5, pax, socperf, vtsspp) were built for ${KV_FULL}."
		elog "Load them with '${VTUNE_ROOT}/sepdk/src/insmod-sep -g <group>' or via"
		elog "/etc/modules-load.d. Device nodes default to the group given to insmod-sep;"
		elog "add your user to it. Re-emerge after every kernel upgrade."
	fi
}

pkg_postrm() {
	xdg_pkg_postrm
}
