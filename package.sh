#!/bin/sh -e
#
#  Copyright 2021, Roger Brown
#
#  This file is part of rhubarb pi.
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
# $Id: package.sh 74 2021-11-29 20:39:04Z rhubarb-geek-nz $
#

if test 0 -eq $(id -u)
then
	echo This should not need to be run as root, stay safe out there. 1>&2
	false
fi

THIS="$0"
MAKERPM=false
MAKEDEB=false

svn log -q "$THIS" > /dev/null

SVNVERS=$(svn log -q "$THIS" | grep -v "\----------" | wc -l)

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
	for d in rpms rpm.spec data
	do
		if test -w "$d"
		then
			rm -rf "$d"
		fi
	done
}

cleanup

trap cleanup 0

for d in $(. /etc/os-release ; echo $ID $ID_LIKE)
do
	case "$d" in
		debian | ubuntu )
			MAKEDEB=true
			;;
		suse | opensuse | rhel | centos | fedora )
			MAKERPM=true
			;;
		* )
			;;
	esac

	if $MAKEDEB
	then
		break
	fi

	if $MAKERPM
	then
		break
	fi
done

test -n "$SVNVERS"

ID=$(osRelease ID | sed "y/-/./")
VERSION_ID=$(osRelease VERSION_ID)
RELEASE="1.$ID.$VERSION_ID"
VERSION="1.0.$SVNVERS"

if $MAKERPM
then
	mkdir data
	mkdir -p data/lib/systemd/system
	cat > data/lib/systemd/system/dtlogin.service <<EOF
[Unit]
Description=Common Desktop Environment Login Manager
Documentation=man:dtlogin(1)
Conflicts=getty@tty1.service
Requires=rpcbind.service
After=getty@tty1.service systemd-user-sessions.service plymouth-quit.service

[Service]
ExecStart=/usr/dt/bin/dtlogin -nodaemon

[Install]
Alias=display-manager.service
EOF

	DEPENDS="dtlogin, rpcbind, xset, xsetroot, xrdb, motif"

	case "$ID" in
		opensuse | opensuse.* | suse )
			DEPENDS="$DEPENDS, terminfo, xorg-x11-server"
			;;
		fedora | centos | rocky | almalinux )
			DEPENDS="$DEPENDS, ncurses-term, xorg-x11-server-Xorg, xorg-x11-fonts-misc, xorg-x11-fonts-75dpi, xorg-x11-fonts-100dpi, xorg-x11-fonts-Type1, xorg-x11-fonts-ISO8859-1-75dpi, xorg-x11-fonts-ISO8859-1-100dpi, xorg-x11-drivers"
			;;
		*)
			TERMINFO=/usr/share/terminfo/d/dtterm

			ls -ld "$TERMINFO"

			rpm -q --whatprovides "$TERMINFO"

			TERMINFO_RPM=$(rpm -q --qf "%{NAME}" --whatprovides "$TERMINFO")

			if (echo $DEPENDS | grep -v ", $TERMINFO_RPM," > /dev/null)
			then
				DEPENDS="$DEPENDS, $TERMINFO_RPM"
			fi
			;;
	esac


	cat > rpm.spec << EOF
Summary: Common Desktop Environment Login Manager
Name: dtlogin-service
Version: $VERSION
Release: $RELEASE
Requires: $DEPENDS
BuildArch: noarch
License: LGPLv2+
Group: User Interface/X
URL: https://sourceforge.net/p/cdesktopenv/wiki/CentOSBuild/
Prefix: /lib/systemd/system

%description
CDE - The Common Desktop Environment is X Windows desktop 
environment that was commonly used on commercial UNIX variants 
such as Sun Solaris, HP-UX and IBM AIX. Developed between 1993 
and 1999, it has now been released under an Open Source 
licence by The Open Group.

%files
%defattr(-,root,root)
/lib/systemd/system/dtlogin.service

%clean
EOF

	PWD=$(pwd)
	rpmbuild --buildroot "$PWD/data" --define "_rpmdir $PWD/rpms" -bb "$PWD/rpm.spec"
fi

rm -rf data

if $MAKEDEB
then

	mkdir -p data/DEBIAN data/lib/systemd/system

	cat > data/lib/systemd/system/dtlogin.service << EOF
[Unit]
Description=CDE Login Manager
Requires=rpcbind.service
After=systemd-user-sessions.service

[Service]
ExecStart=/usr/dt/bin/dtlogin -nodaemon

[Install]
Alias=display-manager.service
EOF

	SIZE=$(du -sk data | while read A B; do echo $A; break; done)

	cat > data/DEBIAN/control << EOF
Package: dtlogin-service
Version: $VERSION-$RELEASE
Architecture: all
Depends: dtlogin, rpcbind, xserver-xorg-input-all, xserver-xorg-video-fbdev, xfonts-intl-european
Section: x11
Priority: optional
Homepage: https://sourceforge.net/p/cdesktopenv/wiki/CDE%20on%20the%20Raspberry%20Pi/
Installed-Size: $SIZE
Maintainer: rhubarb-geek-nz@users.sourceforge.net
Description: CDE Login Manager
EOF

	dpkg-deb --root-owner-group --build data dtlogin-service_"$VERSION-$RELEASE"_all.deb

	rm -rf data
fi

if test -d rpms
then
	find rpms -type f -name "*.rpm" | while read N
	do
		mv "$N" .
		basename "$N"
	done
fi
