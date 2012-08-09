# $NetBSD: Makefile,v 1.5 2008/01/06 02:13:02 adrianp Exp $
#

DISTNAME=	minimal-0.1
PKGREVISION= 2
CATEGORIES=	meta-pkgs
MASTER_SITES=	# empty
DISTFILES=	# empty

MAINTAINER=	415fox@gmail.com
# TODO: fill in with github project when up:
HOMEPAGE=	http://www.github.com/
COMMENT=	Meta-package for installing some minimally-built tools.

DEPENDS+=	lua>=5.1:../lua
# TODO: more minimal scmgit-base dissabling everything possible (unfortunately perl can't be)
DEPENDS+=	scmgit-base>=1.7.10:../../devel/scmgit-base

META_PACKAGE=	yes

.include "../../mk/bsd.pkg.mk"
