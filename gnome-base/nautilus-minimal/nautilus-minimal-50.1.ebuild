# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit desktop python-single-r1 xdg

DESCRIPTION="GNOME Files (Nautilus) as a self-contained /opt directory (bundled deps)"
HOMEPAGE="https://github.com/authorisation/nautilus-minimal"

REPO="nautilus-minimal"
COMMIT="d7d0c80339ba9f7e5e3df05412c9ce518d9f40f0"
SRC_URI="https://github.com/authorisation/${REPO}/archive/${COMMIT}.tar.gz -> ${REPO}-${COMMIT}.tar.gz"
S="${WORKDIR}/${REPO}-${COMMIT}"

LICENSE="GPL-3+ LGPL-2.1+ GPL-2+ LGPL-2+ LGPL-3+ BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~loong ~ppc64 ~riscv ~x86"

IUSE="+strip-locale keep-dev gvfs video-thumbnails localsearch heif jpegxl svg python"

RESTRICT="network-sandbox test mirror"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	>=dev-libs/glib-2.84.0:2
	>=gui-libs/gtk-4.20:4[introspection]
	media-libs/glycin[gtk]
	media-libs/glycin-loaders[heif?,jpegxl?,svg?]
	>=gnome-base/gsettings-desktop-schemas-46
	app-text/iso-codes
	>=dev-libs/libyaml-0.2
	net-misc/curl
	dev-libs/libxml2
	app-arch/zstd:=
	app-arch/xz-utils
	dev-db/sqlite:3
	app-arch/libarchive:=
	net-libs/libsoup:3.0
	dev-libs/json-glib
	>=dev-libs/icu-56:=
	dev-libs/fribidi
	x11-libs/pango
	x11-libs/gdk-pixbuf:2
	gvfs? ( gnome-base/gvfs )
	video-thumbnails? ( media-video/ffmpegthumbnailer )
	localsearch? ( app-misc/localsearch )
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-python/pygobject:3[${PYTHON_USEDEP}]
		')
	)
"
DEPEND="
	>=dev-libs/glib-2.84.0:2
	>=gui-libs/gtk-4.20:4[introspection]
	media-libs/glycin[gtk]
	>=gnome-base/gsettings-desktop-schemas-46
	app-text/iso-codes
	>=dev-libs/libyaml-0.2
	net-misc/curl
	dev-libs/libxml2
	app-arch/zstd:=
	app-arch/xz-utils
	dev-db/sqlite:3
	app-arch/libarchive:=
	net-libs/libsoup:3.0
	dev-libs/json-glib
	>=dev-libs/icu-56:=
	dev-libs/fribidi
	x11-libs/pango
	x11-libs/gdk-pixbuf:2
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-python/pygobject:3[${PYTHON_USEDEP}]
		')
	)
"
BDEPEND="
	dev-build/meson
	dev-build/ninja
	dev-vcs/git
	dev-util/blueprint-compiler
	dev-lang/sassc
	dev-lang/vala
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
	# patchelf + vendored schema + launcher + prune) is done by the repo
	# script, staged into ${D} via NAUTILUS_DESTDIR. NAUTILUS_PREFIX is the
	# *runtime* path baked into config.h; the script passes DESTDIR=${D} to
	# `ninja install` and applies all post-install steps under
	# ${D}${NAUTILUS_PREFIX}. No system files are touched.
	# nautilus-python embeds libpython: pin the build to the same Python target
	# python-single-r1 selected, so the script's meson `python3` lookup and the
	# resulting .so's libpython soname match the runtime ${PYTHON_DEPS}.
	use python && python_setup

	NAUTILUS_PREFIX="${EPREFIX}/opt/nautilus" \
	NAUTILUS_DESTDIR="${D}" \
	STRIP_LOCALE="$(usex strip-locale 1 0)" \
	KEEP_DEV="$(usex keep-dev 1 0)" \
	NAUTILUS_PYTHON="$(usex python 1 0)" \
		bash "${S}"/build-aux/contained-setup.sh || die "contained-setup.sh failed"

	cat > "${T}"/nautilus-contained.desktop <<-EOF
[Desktop Entry]
Type=Application
Version=501
Name=Files
GenericName=File Manager
Comment=Browse the file system with the self-contained Nautilus
Exec=/usr/bin/nautilus %U
Icon=/opt/nautilus/share/icons/hicolor/scalable/apps/org.gnome.Nautilus.svg
Terminal=false
StartupNotify=true
DBusActivatable=false
Categories=GTK;GNOME;System;Utility;Core;FileManager;
MimeType=inode/directory;application/x-gnome-saved-search;
Keywords=folder;manager;explore;disk;filesystem;directory;
EOF
	domenu "${T}"/nautilus-contained.desktop


	dosym /opt/nautilus/bin/nautilus.sh /usr/bin/nautilus
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "* Be very careful with this piece of software"
	elog "* I have no idea what abomination I created here but lets see"
	elog "* Just run using /usr/bin/nautilus"
	elog "*"
	elog "* Optional USE flags (pure runtime, no rebuild needed):"
	elog "*   video-thumbnails - ffmpegthumbnailer for video thumbnails"
	elog "*   heif/jpegxl/svg  - extra glycin image loaders (preview+thumbs)"
	elog "*   gvfs (default on)- trash:// recent:// network mounts (mtp etc.)"
	elog "*   localsearch      - full indexed search daemon (else recursive)"
	elog "*"
	elog "* python (NOT pure-runtime; changes the build): bundles"
	elog "*   nautilus-python. Drop Python extensions into:"
	elog "*     /opt/nautilus/share/nautilus-python/extensions/   or"
	elog "*     ~/.local/share/nautilus-python/extensions/"
	elog "*   Re-emerge after a Python upgrade (embedded libpython soname)."
}
