# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake xdg

DESCRIPTION="KeePassXC - KeePass Cross-platform Community Edition, QT6 fork by varjolintu"
HOMEPAGE="https://keepassxc.org"

GIT_HASH="48009926399a0f53c6b38c6a8c303119feb71f0d"
SRC_URI="https://github.com/varjolintu/keepassxc/archive/${GIT_HASH}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/${PN}-${GIT_HASH}"

# COPYING order
KEYWORDS="~amd64"
LICENSE="|| ( GPL-2 GPL-3 ) BSD LGPL-2.1 MIT LGPL-2 CC0-1.0 Apache-2.0 GPL-2+ BSD-2"
SLOT="0"
IUSE="X browser -doc -keyring +network -ssh-agent test"

RESTRICT="!test? ( test )"

# Include path changed in zxcvbn-c-2.6
RDEPEND="
	dev-libs/libusb:1
	dev-libs/zxcvbn-c
	dev-qt/qtbase:6
	dev-qt/qtsvg:6
	media-gfx/qrencode:=
	sys-apps/pcsc-lite
	sys-apps/keyutils
	sys-libs/readline:0=
	virtual/minizip:=
	virtual/zlib:=
	>dev-libs/botan-3.0.0
	X? (
		dev-qt/qtbase:6[X]
		x11-libs/libXext
		x11-libs/libX11
		x11-libs/libXi
		x11-libs/libXtst
	)
	browser? (
		dev-qt/qtbase:6[dbus]
	)
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	dev-qt/qttools:6[linguist]
	doc? (
		dev-ruby/asciidoctor
	)
"

PATCHES=(
		"${FILESDIR}/${PN}-2.7.10-tests.patch"
		"${FILESDIR}/${PN}-2.8.0-cmake_minimum.patch"
)

src_prepare() {
	# browser & keyring useflags depend on dbus, so we only patch dbus out if they're disabled
	if ! use browser && ! use keyring; then
        PATCHES+=( "${FILESDIR}/${PN}-2.8.0-no_dbus.patch" )
    fi

	if ! [[ "${PV}" =~ _beta|9999 ]]; then
		echo "${PV}" > .version || die
	fi

	sed -i 's/\r$//' \
		src/cli/DatabaseCommand.cpp \
		src/thirdparty/CMakeLists.txt || die

	# Unbundle zxcvbn, bug 958062
	rm -r ./src/thirdparty/zxcvbn || die

	if has_version "<dev-libs/zxcvbn-c-2.6" ; then
		eapply "${FILESDIR}"/${PN}-2.7.10-zxcvbn.patch
	fi

	cmake_src_prepare
}

src_configure() {
	local -a mycmakeargs=(
		# Gentoo users enable ccache via e.g. FEATURES=ccache or
		# other means. We don't want the build system to enable it for us.
		-DWITH_CCACHE="OFF"
		-DWITH_GUI_TESTS="OFF"
		-DKPXC_FEATURE_UPDATES="OFF"

		-DWITH_TESTS="$(usex test)"
		-DKPXC_FEATURE_BROWSER="$(usex browser)"
		-DKPXC_FEATURE_DOCS="$(usex doc)"
		-DKPXC_FEATURE_FDOSECRETS="$(usex keyring)"
		-DKPXC_FEATURE_NETWORK="$(usex network)"
		-DKPXC_FEATURE_SSHAGENT="$(usex ssh-agent)"
		-DWITH_X11="$(usex X)"
	)

	if [[ "${PV}" == *_beta* ]] ; then
		mycmakeargs+=(
			-DOVERRIDE_VERSION="${PV/_/-}"
		)
	fi

	cmake_src_configure
}

pkg_postinst() {
	if ! use browser && ! use keyring; then
		ewarn "NOTICE: Due to the browser and keyring useflags being disabled, a dbus removal patch was applied!"
		ewarn "This can cause issues and is experimental so caution is advised."
		ewarn ""
		ewarn "The following features will **NOT** work:"
		ewarn " - Auto locking when screen locks or suspends"
		ewarn " - Some stuff related to theme changes system wide will not be recognized"
		ewarn " - Among possibly other things ..."
		ewarn ""
		ewarn "You have been warned!"
	fi
}
