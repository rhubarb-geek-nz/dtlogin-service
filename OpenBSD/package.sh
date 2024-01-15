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
PKGNAME=dtlogin-init-$VERSION.tgz
PKGLIST="cdesktopenv"

clean()
{
	rm -rf meta root
}

trap clean 0

clean

mkdir -p "root/etc/rc.d" "meta"

cat >"root/etc/rc.d/cmsd" <<'EOF'
daemon="/usr/dt/bin/rpc.cmsd &"

. /etc/rc.d/rc.subr

pexp="rpc.cmsd: ${daemon}${daemon_flags:+ ${daemon_flags}} \[listener\].*"

rc_reload() {
        ${daemon} ${daemon_flags} -t && pkill -HUP -xf "${pexp}"
}

rc_cmd $1
EOF

cat >"root/etc/rc.d/dtlogin" <<'EOF'
#!/bin/ksh

daemon="/usr/dt/bin/dtlogin"

. /etc/rc.d/rc.subr

rc_reload=NO

if [ -n "${INRC}" ]; then
# on boot: make sure we don't hang in _rc_wait
_rc_wait() {
	return 0
}
# on boot: wait for ttys to be initialized
rc_start() {
	( local i=0
		while ! pgrep -qf "^/usr/libexec/getty "; do
		sleep 1
		[ $((i++)) -ge 10 ] && return 1
	done
	${rcexec} "${daemon} ${daemon_flags}" ) &
}
fi

rc_cmd $1
EOF

chmod +x "root/etc/rc.d/cmsd" "root/etc/rc.d/dtlogin"

cat > "meta/CONTENTS" << EOF
etc/rc.d/cmsd
etc/rc.d/dtlogin
EOF

cat >"meta/DESC" <<EOF
Init script for CDE dtlogin
EOF

COMMENT="dtlogin init script"
MAINTAINER=rhubarb-geek-nz@users.sourceforge.net
FULLPKGPATH=x11/cde/dtlogin
HOMEPAGE=https://sourceforge.net/p/rhubarb-pi/wiki/pkg-dtlogin/
FTP=yes
PKGDEPS=

for d in $PKGLIST
do
	pkg_info -P -q $d
	pkg_info -I -q $d
	PKGPATH=$(pkg_info -P -q $d)
	PKGSPEC=$(pkg_info -I -q $d)
	PKGDEPS="$PKGDEPS -P $PKGPATH:$d-*:$PKGSPEC"
done

pkg_create \
		-A "*" \
		-d "meta/DESC" \
		$PKGDEPS \
		-D "COMMENT=$COMMENT" \
		-D "HOMEPAGE=$HOMEPAGE" 		\
		-D "FULLPKGPATH=$FULLPKGPATH" \
		-D "MAINTAINER=$MAINTAINER" \
		-D "FTP=$FTP" \
		-f "meta/CONTENTS" \
		-B "root" \
		-p / \
		"$PKGNAME"
