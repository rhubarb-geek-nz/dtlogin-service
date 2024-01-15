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

osRelease()
{
	(
		set -e
		. /etc/os-release
		case "$1" in
			ID )
				echo "$ID"
				;;
			VERSION_ID )
				echo "$VERSION_ID"
				;;
			* )
			;;
		esac
	)
}

cleanup()
{
	rm -rf data cdesktopenv-code
}

cleanup

trap cleanup 0

test -n "$SVNVERS"

ID=$(osRelease ID | sed "y/-/./")
VERSION_ID=$(osRelease VERSION_ID)
RELEASE="1.$ID.$VERSION_ID"
VERSION="1.0.$SVNVERS"

git clone --recursive --branch 2.3.2 --single-branch https://git.code.sf.net/p/cdesktopenv/code cdesktopenv-code

mkdir -p data/DEBIAN data/etc/init.d

cp cdesktopenv-code/cde/contrib/rc/linux/dtlogin data/etc/init.d

chmod +x data/etc/init.d/dtlogin

SIZE=$(du -sk data | while read A B; do echo $A; break; done)

cat > data/DEBIAN/control << EOF
Package: dtlogin-init
Version: $VERSION-$RELEASE
Architecture: all
Depends: dtlogin, rpcbind, xserver-xorg-input-all, xserver-xorg-video-fbdev, xfonts-intl-european, xinit
Section: x11
Priority: optional
Homepage: https://sourceforge.net/p/cdesktopenv/wiki/Linux%20-%20Autostart%20dtlogin%20on%20boot/
Installed-Size: $SIZE
Maintainer: rhubarb-geek-nz@users.sourceforge.net
Description: CDE Login Manager
EOF

cat > data/DEBIAN/postinst << EOF
#!/bin/sh -ex
update-rc.d dtlogin defaults
EOF

cat > data/DEBIAN/postrm << EOF
#!/bin/sh -ex
if update-rc.d dtlogin remove
then
	:
fi
EOF

chmod +x data/DEBIAN/postinst data/DEBIAN/postrm

dpkg-deb --root-owner-group --build data dtlogin-init_"$VERSION-$RELEASE"_all.deb
