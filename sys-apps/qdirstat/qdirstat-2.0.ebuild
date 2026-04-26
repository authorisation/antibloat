# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit qmake-utils xdg-utils

DESCRIPTION="(Unofficial) Qt-based directory statistics"
HOMEPAGE="https://github.com/shundhammer/qdirstat"
SRC_URI="https://github.com/shundhammer/qdirstat/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"

DEPEND="
	dev-qt/qtbase:6[gui,widgets]
	virtual/zlib:=
"
RDEPEND="${DEPEND}
	dev-lang/perl
	dev-perl/URI
"

PATCHES=(
		"${FILESDIR}/${PN}-2.0-qt5compat_removal.patch"
)

src_prepare() {
	default

	# Fix QA warning about incorrect use of doc path
	sed -e "/doc.path/s/${PN}/${PF}/" -i doc/doc.pro doc/stats/stats.pro || die

	# Don't install compressed man pages
	sed -e '/gzip/d' -e 's/.gz//g' -i man/man.pro || die
}

src_configure() {
	eqmake6
}

src_install() {
	emake INSTALL_ROOT="${ED}" install
}

pkg_postinst() 
{
	xdg_desktop_database_update
	xdg_icon_cache_update
	ewarn "NOTICE: This is not the official package from the gentoo repos!"
	ewarn "This features a possibly destructive/broken patch to remove the qt5compat package"
	ewarn "and removes the compatibility layer for qt5, this patch is rather big so unexpected things may occur!"
	ewarn "Caution is advised!"
	ewarn "Do **NOT** report issues to the upstream repo of this software when using this or the the gentoo repos!"
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
