# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="File Roller archive manager as a self-contained /opt directory (bundled deps)"
HOMEPAGE="https://github.com/authorisation/fileroller-minimal"

REPO="fileroller-minimal"
COMMIT="e19c571cd1ec70a28137382ce3b5a0fad0fa95f6"
SRC_URI="https://github.com/authorisation/${REPO}/archive/${COMMIT}.tar.gz -> ${REPO}-${COMMIT}.tar.gz"
S="${WORKDIR}/${REPO}-${COMMIT}"

LICENSE="GPL-2+ LGPL-2.1+ LGPL-3+ BSD-2 MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~loong ~ppc64 ~riscv ~x86"

IUSE="+strip-locale keep-dev gvfs nautilus"

RESTRICT="network-sandbox test mirror"

RDEPEND="
	>=dev-libs/glib-2.84.0:2
	>=gui-libs/gtk-4.8:4
	app-arch/libarchive:=
	dev-libs/json-glib
	app-arch/cpio
	net-misc/curl
	dev-libs/libxml2
	>=dev-libs/libyaml-0.2
	app-arch/xz-utils
	app-arch/zstd:=
	dev-libs/fribidi
	x11-libs/pango
	x11-libs/gdk-pixbuf:2
	gvfs? ( gnome-base/gvfs )
	nautilus? ( gnome-base/nautilus-minimal[keep-dev] )
"
DEPEND="
	>=dev-libs/glib-2.84.0:2
	>=gui-libs/gtk-4.8:4
	app-arch/libarchive:=
	dev-libs/json-glib
	net-misc/curl
	dev-libs/libxml2
	>=dev-libs/libyaml-0.2
	app-arch/xz-utils
	app-arch/zstd:=
	dev-libs/fribidi
	x11-libs/pango
	x11-libs/gdk-pixbuf:2
	nautilus? ( gnome-base/nautilus-minimal[keep-dev] )
"
BDEPEND="
	dev-build/meson
	dev-build/ninja
	dev-vcs/git
	dev-lang/sassc
	>=dev-libs/gobject-introspection-1.54
	dev-util/gperf
	dev-util/glib-utils
	>=dev-util/gdbus-codegen-2.51.2
	>=sys-devel/gettext-0.19.8
	dev-util/patchelf
	virtual/pkgconfig
"

src_compile() {
	# Build + stage are both driven by the repo script in src_install (it
	# couples configure/build/install); nothing to do here.
	:
}

src_install() {
	# Everything (configure + bundled-subproject build/fetch + install +
	# patchelf + schema recompile + launcher + prune) is done by the repo
	# script, staged into ${D} via FILE_ROLLER_DESTDIR. FILE_ROLLER_PREFIX is
	# the *runtime* path baked into config.h; the script passes DESTDIR=${D}
	# to `ninja install` and applies all post-install steps under
	# ${D}${FILE_ROLLER_PREFIX}. No system files are touched by the script;
	# the /usr wiring below is done by the ebuild (same as nautilus-minimal).
	#
	# nautilus?: the script also builds libnautilus-fileroller.so against the
	# contained Nautilus' libnautilus-extension-4 (nautilus-minimal[keep-dev])
	# and stages it into ${D}/opt/nautilus/lib/nautilus/extensions-4/ — the
	# only file this package writes outside /opt/file-roller, because Nautilus
	# has a single non-overridable extension dir. No portage collision (unique
	# filename); re-emerge this if nautilus-minimal is reinstalled.
	FILE_ROLLER_PREFIX="${EPREFIX}/opt/file-roller" \
	FILE_ROLLER_DESTDIR="${D}" \
	FILE_ROLLER_NAUTILUS="$(usex nautilus 1 0)" \
	FILE_ROLLER_NAUTILUS_PREFIX="${EPREFIX}/opt/nautilus" \
	STRIP_LOCALE="$(usex strip-locale 1 0)" \
	KEEP_DEV="$(usex keep-dev 1 0)" \
		bash "${S}"/build-aux/contained-setup.sh || die "contained-setup.sh failed"

	cat > "${T}"/file-roller-contained.desktop <<-EOF
[Desktop Entry]
Type=Application
Version=446
Name=Archive Manager
GenericName=Archive Manager
Comment=Create and modify archives with the self-contained File Roller
Exec=/usr/bin/file-roller %U
Icon=/opt/file-roller/share/icons/hicolor/scalable/apps/org.gnome.FileRoller.svg
Terminal=false
StartupNotify=true
DBusActivatable=false
Categories=GTK;GNOME;Utility;Archiving;Compression;
MimeType=application/bzip2;application/gzip;application/vnd.android.package-archive;application/vnd.ms-cab-compressed;application/vnd.debian.binary-package;application/vnd.rar;application/x-7z-compressed;application/x-7z-compressed-tar;application/x-ace;application/x-alz;application/x-apple-diskimage;application/x-ar;application/x-archive;application/x-arj;application/x-brotli;application/x-bzip-brotli-tar;application/x-bzip;application/x-bzip-compressed-tar;application/x-bzip1;application/x-bzip1-compressed-tar;application/x-bzip3;application/x-bzip3-compressed-tar;application/x-cabinet;application/x-cd-image;application/x-compress;application/x-compressed-tar;application/x-cpio;application/x-chrome-extension;application/x-deb;application/x-ear;application/x-ms-dos-executable;application/x-gtar;application/x-gzip;application/x-gzpostscript;application/x-java-archive;application/x-lha;application/x-lhz;application/x-lrzip;application/x-lrzip-compressed-tar;application/x-lz4;application/x-lzip;application/x-lzip-compressed-tar;application/x-lzma;application/x-lzma-compressed-tar;application/x-lzop;application/x-lz4-compressed-tar;application/x-ms-wim;application/x-rar;application/x-rar-compressed;application/x-rpm;application/x-source-rpm;application/x-rzip;application/x-rzip-compressed-tar;application/x-tar;application/x-tarz;application/x-tzo;application/x-stuffit;application/x-war;application/x-xar;application/x-xz;application/x-xz-compressed-tar;application/x-zip;application/x-zip-compressed;application/x-zstd-compressed-tar;application/x-zoo;application/zip;application/zstd;
Keywords=zip;tar;extract;unpack;archive;compression;
EOF
	domenu "${T}"/file-roller-contained.desktop

	dosym /opt/file-roller/bin/file-roller.sh /usr/bin/file-roller
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "* Be very careful with this piece of software"
	elog "* I have no idea what abomination I created here but lets see"
	elog "* Just run using /usr/bin/file-roller"
	elog "*"
	elog "* libadwaita + appstream + libxmlb are bundled under /opt/file-roller;"
	elog "* gtk4/glib/libarchive/curl/libxml2/libyaml/xz/zstd stay system libs."
	elog "*"
	elog "* Optional USE flags (pure runtime, no rebuild needed):"
	elog "*   gvfs - trash://, recent://, network/MTP mounts via GIO"
	if use nautilus; then
		elog "*   NOTE: re-emerge fileroller-minimal after reinstalling/upgrading"
		elog "*   gnome-base/nautilus-minimal (the .so lives in its tree)."
	fi
}
