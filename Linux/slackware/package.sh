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

if test 0 -eq $(id -u)
then
	echo This should not need to be run as root, stay safe out there. 1>&2
	false
fi

THIS="$0"
SVNVERS=$(git log --oneline "$THIS" | wc -l)

OSID=slack
OSVER=$(. /etc/os-release ; echo $VERSION_ID)
PKGARCH=noarch
VERSION=1.0
PKGNAME=dtlogin-init

PKGFILE="$PKGNAME-$VERSION-$PKGARCH-$SVNVERS"_"$OSID$OSVER.txz"

cleanup()
{
	rm -rf data
}

cleanup

trap cleanup 0

mkdir -p  data/install data/etc/rc.d

cat > data/install/slack-desc << EOF
        |-----handy-ruler------------------------------------------------------|
$PKGNAME: CDE - Common Desktop Environment
$PKGNAME:
$PKGNAME: The Common Desktop Environment was created by a collaboration of Sun,
$PKGNAME: HP, IBM, DEC, SCO, Fujitsu and Hitachi. Used on a selection of
$PKGNAME: commercial UNIXs, it is now available as open-source software for the
$PKGNAME: first time.
$PKGNAME:
$PKGNAME: Dtlogin provides the login
$PKGNAME:
$PKGNAME: Enable the init script at /etc/rc.d/rc.dtlogin for boot
$PKGNAME:
EOF

cat > data/etc/rc.d/rc.dtlogin << EOF
#!/bin/sh
#
# /etc/rc.d/rc.dtlogin
#
# Start/stop/restart the dtlogin daemon.
#
# To make dtlogin start automatically at boot, make this
# file executable:  chmod 755 /etc/rc.d/rc.dtlogin
#

case "\$1" in
	'start')
		/usr/dt/bin/dtlogin -daemon
		;;
	'stop')
		pkill dtlogin
		;;
	'restart')
		pkill dtlogin
		sleep 5
		/usr/dt/bin/dtlogin -daemon
		;;
	*)
		echo "Usage: \$0 {start|stop|restart}"
		;;
esac
EOF

find data -type f | xargs chmod -w

(
	cd data

	mkdir dot

	tar --owner=0 --group=0 --create --xz --file "../$PKGFILE" -C dot . -C .. etc install
)
