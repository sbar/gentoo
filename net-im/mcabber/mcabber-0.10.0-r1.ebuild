# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-im/mcabber/mcabber-0.10.0-r1.ebuild,v 1.4 2010/10/13 20:10:59 maekke Exp $

EAPI=3

inherit flag-o-matic

DESCRIPTION="A small Jabber console client with various features, like MUC, SSL, PGP"
HOMEPAGE="http://mcabber.com/"
SRC_URI="http://mcabber.com/files/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 ~mips ~ppc ~ppc64 ~sparc x86"

IUSE="aspell crypt idn modules otr spell ssl vim-syntax"

LANGS="cs de fr it nl pl ru uk"
# localized help versions are installed only, when LINGUAS var is set
for i in ${LANGS}; do
	IUSE="${IUSE} linguas_${i}"
done;

RDEPEND="crypt? ( >=app-crypt/gpgme-1.0.0 )
	otr? ( >=net-libs/libotr-3.1.0 )
	aspell? ( app-text/aspell )
	vim-syntax? ( || ( app-editors/vim app-editors/gvim ) )
	idn? ( net-dns/libidn  )
	spell? ( app-text/enchant )
	dev-libs/glib:2
	sys-libs/ncurses
	>=net-libs/loudmouth-1.4.3-r1[ssl?]"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

pkg_setup() {
	if use aspell && use spell; then
		ewarn "NOTE: You have both flags 'aspell' and 'spell' enabled, enchant will be preferred."
	fi
}

src_configure() {
	epatch "${FILESDIR}"/mcabber-os-0.10.0.patch

	# bug #277888
	use crypt && append-flags -D_FILE_OFFSET_BITS=64

	econf \
		$(use_enable crypt gpgme) \
		$(use_enable otr) \
		$(use_enable aspell) \
		$(use_enable spell enchant) \
		$(use_enable modules) \
		$(use_with idn libidn)
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"

	# clean unneeded language documentation
	for i in ${LANGS}; do
		! use linguas_${i} && rm -rf "${D}"/usr/share/${PN}/help/${i}
	done

	dodoc AUTHORS ChangeLog NEWS README TODO mcabberrc.example
	dodoc doc/README_PGP.txt

	# contrib themes
	insinto /usr/share/${PN}/themes
	doins "${S}"/contrib/themes/* || die

	# contrib generic scripts
	exeinto /usr/share/${PN}/scripts
	doexe "${S}"/contrib/*.{pl,py} || die

	# contrib event scripts
	exeinto /usr/share/${PN}/scripts/events
	doexe "${S}"/contrib/events/* || die

	if use vim-syntax; then
		cd contrib/vim/

		insinto /usr/share/vim/vimfiles/syntax
		doins mcabber_log-syntax.vim || die

		insinto /usr/share/vim/vimfiles/ftdetect
		doins mcabber_log-ftdetect.vim || die
	fi
}

pkg_postinst() {
	elog
	elog "MCabber requires you to create a subdirectory .mcabber in your home"
	elog "directory and to place a configuration file there."
	elog "An example mcabberrc was installed as part of the documentation."
	elog "To create a new mcabberrc based on the example mcabberrc, execute the"
	elog "following commands:"
	elog
	elog "  mkdir -p ~/.mcabber"
	elog "  bzcat ${ROOT}usr/share/doc/${PF}/mcabberrc.example.bz2 >~/.mcabber/mcabberrc"
	elog
	elog "Then edit ~/.mcabber/mcabberrc with your favorite editor."
	elog
	elog "See the CONFIGURATION FILE and FILES sections of the mcabber"
	elog "manual page (section 1) for more information."
	elog
	elog "From version 0.9.0 on, MCabber supports PGP encryption of messages."
	elog "See README_PGP.txt for details."
	echo
	einfo "Check out ${ROOT}usr/share/${PN} for contributed themes and event scripts."
	echo
}
