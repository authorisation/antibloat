EAPI=8

DESCRIPTION="A lightweight text editor written in Lua"
HOMEPAGE="https://lite-xl.com https://github.com/lite-xl/lite-xl"
SRC_URI="https://github.com/lite-xl/lite-xl/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~x86"

inherit meson xdg

DEPEND="
	dev-lang/lua:5.4
	dev-libs/libpcre2
	media-libs/freetype
	media-libs/libsdl3
"
RDEPEND="${DEPEND}"
BDEPEND="
	dev-build/meson
	dev-build/ninja
"

src_prepare() {
	default

	# Force shared SDL3 (upstream defaults to static for portable builds)
	sed -i "s/'sdl3', static: true/'sdl3', static: false/" src/meson.build || die

	# Only version the docdir (Gentoo policy). Leave datadir as 'lite-xl'
	# so the runtime path in main.c matches the installed location.
	sed -i "s| / 'doc' / 'lite-xl'| / 'doc' / 'lite-xl-${PV}'|" meson.build || die
}

src_configure() {
	local emesonargs=(
		-Duse_system_lua=true
	)

	meson_src_configure
}

src_install() {
	meson_src_install

	dodoc README.md changelog.md
}
