#!/bin/sh
# Copyright Emmanuel Kasper
# Available under the following license: http://www.netbsd.org/about/redistribution.html#default
# This script strives to be POSIX compliant, and uses GNU tar, curl and 
# openssl
# Later Michael found it on the internet and made a few changes to suit his target systems. 
# Hopefully it retains good qualities.
# Version: 0.2
#
# The mk.conf file will be sugared with:
#
# 	mk.conf.fragment.Common
# 	mk.conf.fragment.ARCH
#
# Where ARCH is one of:
#
# 	Darwin64
# 	Linux32
# 	Linux64
# 	HPUX10
# 	HPUX11
# 	Default
#
# If you're using Default then detecting
#
# TODO: after bootstrap, build git minimal and use it to upgrade pkgsrc


# Debug
#set -o xtrace

# Get canonical path
ca() {
    (cd "$@" && pwd -P) ;
}
UNAME=`uname`
ARCH=`uname -m`

PKG_ROOT=$(ca ".")
PKG="$UNAME"_"$ARCH"
echo PKG: $PKG
WORK_DIR=$PKG_ROOT/pkgsrc/bootstrap/work 
TARBALL=pkgsrc-2012Q2.tar.gz
URL=http://ftp.netbsd.org/pub/pkgsrc/pkgsrc-2012Q2/pkgsrc-2012Q2.tar.gz

echo PKG_ROOT: $PKG_ROOT
echo WORK_DIR: $WORK_DIR

# Fragment based on detected system.
# Default to include an optimized makefile fragment on Linux

# Generate mk.conf fragment
frag() {
	# TODO: for more targets
	# TODO: More architectures
	echo UNAME: $UNAME ARCH: $ARCH

	if [ $UNAME == Darwin ] && [ $ARCH == x86_64 ]; then
		FRAG=mk.conf.fragment.Darwin64
		ABI=64
	elif [ $UNAME == Linux ] && [ $ARCH == i386 ]; then
		FRAG=mk.conf.fragment.Linux32
		ABI=32
	else
		echo I don''t know $UNAME $ARCH.
		FRAG=mk.conf.fragment.Default
		ABI=32
		# TODO: prompt for abort?
	fi
	# TODO: mk.Darwin64 and mk.Defaults
	echo Good luck with $FRAG

	# TODO: This detects the number of reported processors which is often 2X
	# the actual number because Intel hyperthreading reports each thread-core
	# as a processor. Lame. Wonder how to fix that.
	CPUS=$(($(getconf _NPROCESSORS_ONLN)+1)) || \
		 CPUS=1
	cat mk.conf.fragment.Common $FRAG > mk.generated.fragment
	echo "MAKE_JOBS=$CPUS" >> mk.generated.fragment
}

### Functions

usage() {
printf "Usage: $(basename $0)\n"
printf "       $(basename $0) --clean\n"
printf "\n"
printf "Fires up pkgsrc in the current directory.\n"
printf "\n"
printf "       --clean 		Clobbers everything and starts from scratch.\n"
printf "               		Very risky. Do not use.\n"
exit 0
}

die() {
    printf "ERROR: $@\n" >&2
    exit 127
}

# Decorate output
decorate() {
printf "\n"
printf "*************************\n"
printf "$1\n"
printf "*************************\n"
}


download_pkgsrc() {
	if [ -e $TARBALL ]; then
		decorate "Already got $TARBALL. If its broken, delete it or, run with --clean for maximum danger."
	else
		decorate "Downloading latest pkgsrc from $URL"
		curl --progress-bar $URL/$TARBALL --output  $TARBALL
		curl --progress-bar $URL/$TARBALL.MD5 --output  $TARBALL.MD5
		printf "\n"	
	fi
}

cksum_pkgsrc() {
decorate "Integrity check of $TARBALL"
openssl md5 -signature $TARBALL.MD5 $TARBALL \
    || die "Wrong checksum. Consider deleting $TARBALL and $TARBALL.MD5 or run with --clean"
}

untar_pkgsrc() {
decorate "Unpacking"
if [ -e pkgsrc ]; then
	echo "pkgsrc directory already exists. Delete it to do over or run with --clean"
else
	CMD="tar xfz $TARBALL"
	$CMD
	if [ ! $? ]; then
		die "ERROR running: $CMD"
	fi
fi
}

bootstrap_pkgsrc() {
	#TODO: foreach ...
	if [ -e $PKG_ROOT/$PKG ]; then
		echo "$PKG_ROOT/$PKG already exists. Bootstrap will fail so lets not even try. Consider deleting it if this is what you want. Otherwise proceed as if it works good."
	elif [ -e $WORK_DIR ]; then
		echo "$WORK_DIR already exists. Bootstrap will fail so lets not even try. Consider deleting it if this is what you want. Otherwise proceed as if it works good."
	else
		decorate "Boostraping, leaving control now to pkgsrc ..."
		CMD="pkgsrc/bootstrap/bootstrap \
		--prefix=$PKG_ROOT/$PKG \
		--varbase=$PKG_ROOT/$PKG/var \
		--pkgdbdir=$PKG_ROOT/$PKG/var/db/pkg \
		--workdir=$WORK_DIR \
		--mk-fragment=mk.generated.fragment \
		--unprivileged 
		--abi $ABI"
		
		echo $CMD
		$CMD
fi
}
make_my_env() {
	CMD="sed s@PKG_DIR@$PKG_ROOT/$PKG@ my-env.template"
	$CMD > my-env
	chmod +x my-env
}

# Main program 
# Very few options.
while [ $# -gt 0 ]; do
	case $1 in 
	-h)	usage ;;
	--help) usage ;;
	--clean) rm -Rf $TARBALL $TARBALL.MD5 pkgsrc pkg/$PKG ;;
	-*) usage ;;
	--*) usage ;;
	esac
	shift
done

frag
decorate "Here we go."
download_pkgsrc
cksum_pkgsrc
untar_pkgsrc
bootstrap_pkgsrc 
make_my_env
decorate "Environment can be accessed by sourcing\n\t. my-env\nOr by running a command like\n\tmy-env bmake\nOr start an exit-able environment with:\n\tmy-env bash\nConsider adding to your .profile or .bashrc:\n\talias a=$PKG_ROOT/my-env\n"
# TODO: custom environment
# TODO: use new environment to install git

