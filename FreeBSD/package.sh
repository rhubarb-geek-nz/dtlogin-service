#!/bin/sh -e
#
#  Copyright 2021, Roger Brown
#
#  This file is part of rhubarb-geek-nz/dtlogin-service.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

THIS="$0"
SVNVERS=$(git log --oneline "$THIS" | wc -l)
VERSION=1.0.$SVNVERS
PKGNAME=dtlogin-init
OUTDIR_DIST=$(pwd)
OPSYS=$(uname)
OPSYSLOWER=$(uname | tr "[:upper:]" "[:lower:]")
OPSYSREL=$(uname -r | sed "y/./ /" | while read A B; do echo $A; break; done)
DEPLIST=cdesktopenv

clean()
{
	rm -rf MANIFEST PLIST root cdesktopenv-code
}

trap clean 0

clean

git clone --recursive --branch 2.4.0 --single-branch https://git.code.sf.net/p/cdesktopenv/code cdesktopenv-code

mkdir -p root/usr/local/etc/rc.d

cp cdesktopenv-code/cde/contrib/rc/freebsd/dtlogin root/usr/local/etc/rc.d/dtlogin

chmod +x root/usr/local/etc/rc.d/dtlogin

(
	cat <<EOF
name $PKGNAME
version $VERSION
desc dtlogin init for $OPSYS:$OPSYSREL
www https://sourceforge.net/p/cdesktopenv/wiki/FreeBSDBuild/
origin x11/cde/dtlogin
comment dtlogin init for $OPSYS:$OPSYSREL
maintainer rhubarb-geek-nz@users.sourceforge.net
arch $OPSYSLOWER:$OPSYSREL:*
abi $OPSYS:$OPSYSREL:*
prefix /usr/local/etc
licenses: [
    "LGPL2"
]
categories: [
    "x11"
]
EOF
	echo "deps: {"
	for d in $DEPLIST
	do
		ORIGIN=$(pkg info -q --origin $d)
		VERS=$(pkg info $d | grep Version | while read A B C D; do echo $C; break; done | sed "y/,/ /" | while read E F; do echo $E; done)
		if test "$d" = "cdesktopenv"
		then
			echo "   $d: {origin: $ORIGIN, version: $VERS}"
		else
			echo "   $d: {origin: $ORIGIN, version: $VERS},"
		fi
	done
	echo "}"
) > MANIFEST

(
	cd root/usr/local/etc
	echo rc.d/dtlogin
) > PLIST

if pkg create -M MANIFEST -o "$OUTDIR_DIST" -r root -v -p PLIST
then
	pkg info -F "$OUTDIR_DIST/$PKGNAME-$VERSION.pkg"
	pkg info -l -d -F "$OUTDIR_DIST/$PKGNAME-$VERSION.pkg"
fi
