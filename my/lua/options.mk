
PKG_OPTIONS_VAR=	PKG_OPTIONS.readline
PKG_SUPPORTED_OPTIONS=	readline
PKG_SUGGESTED_OPTIONS=

.include "../../mk/bsd.options.mk"

.if !empty(PKG_OPTIONS:Mreadline)
.include "../../devel/readline/buildlink3.mk"
CONFIGURE_ARGS+= --with-readline
.else
CONFIGURE_ARGS+= --without-readline
.endif
