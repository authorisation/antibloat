# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Open-source coding-agent CLI for OpenAI, Gemini, DeepSeek, Ollama, etc"
HOMEPAGE="https://github.com/Gitlawb/openclaude"
EGIT_REPO_URI="https://github.com/Gitlawb/openclaude.git"

LICENSE="MIT"
SLOT="0"

PROPERTIES="live"
RESTRICT="network-sandbox"

QA_PREBUILT="opt/${PN}/node_modules/*"

RDEPEND="
		net-libs/nodejs
		sys-apps/ripgrep
"
DEPEND="${RDEPEND}"
BDEPEND="sys-apps/pnpm"

src_compile() {
	einfo "Installing bun locally via pnpm..."
	pnpm add bun || die "Failed to install bun locally"

	einfo "Running bun postinstall script..."
	node node_modules/bun/install.js || die "Bun postinstall failed"

	einfo "Installing project dependencies via local bun..."
	pnpm exec bun install || die "bun install failed"

	einfo "Building OpenClaude..."
	pnpm exec bun run build || die "bun build failed"

	einfo "Pruning project for prod..."
	pnpm prune --prod || die "pnpm prune failed"
}

src_install() {
	# 6. Copy the dist (and required runtime files) to /opt/
	insinto /opt/${PN}
	doins -r bin dist node_modules package.json

	fperms +x /opt/${PN}/bin/openclaude

	dosym ../../opt/${PN}/bin/openclaude /usr/bin/openclaude

	# 9. Install standard documentation (README, LICENSE, etc.)
	#einstalldocs
}
