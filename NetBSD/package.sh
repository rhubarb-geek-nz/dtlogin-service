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

VERS=$(uname -r)
ARCH=$(uname -p)
OPSYS=$(uname -s)

THIS="$0"
SVNVERS=$(git log --oneline "$THIS" | wc -l)
VERSION=1.0.$SVNVERS
PKGNAME=dtlogin-init
PKGDEP="cdesktopenv pam-pwauth_suid"

clean()
{
	rm -rf meta root
}

trap clean 0

clean

mkdir -p root/etc/rc.d  meta

cat > root/etc/rc.d/dtlogin <<'EOF'
#!/bin/sh
#
# $Id: package.sh 90 2021-12-07 21:48:37Z rhubarb-geek-nz $
#

# PROVIDE: dtlogin
# REQUIRE: DAEMON LOGIN wscons
# KEYWORD: shutdown

$_rc_subr_loaded . /etc/rc.subr

name="dtlogin"
rcvar=$name
command="/usr/dt/bin/${name}"
command_args="-daemon"
pidfile=/var/dt/Xpid
extra_commands=""

load_rc_config $name
run_rc_command "$1"
EOF

chmod +x root/etc/rc.d/dtlogin

(
	echo MACHINE_ARCH=$(uname -p)
	echo OPSYS=$(uname -s)
	echo OS_VERSION=$(uname -r)
	echo PKGTOOLS_VERSION=$(pkg_info -V)
) > "meta/BUILD_INFO"

(
	cd root
	echo @name $PKGNAME-$VERSION
	find etc -type f
) > meta/CONTENTS

echo "dtlogin init script" > meta/COMMENT

echo "dtlogin init script for CDE" > meta/DESC

pkg_create -v -B "meta/BUILD_INFO" -P "$PKGDEP" -c "meta/COMMENT" -g wheel -u root -d "meta/DESC" -I / -f "meta/CONTENTS" -p root -F xz "$PKGNAME-$VERSION.tgz"
