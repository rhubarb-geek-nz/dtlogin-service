# rhubarb-geek-nz/dtlogin-service

The purpose of dtlogin is to provide the initial [CDE](https://github.com/rhubarb-geek-nz/cdesktopenv) login screen. This is typically run at the end of the boot process. This page describes the mechanics, for each there is a script to produce a package to assist deployment.

## Linux

See [dtlogin-service](Linux/systemd/package.sh) or [dtlogin-init](Linux/init/package.sh).

Ensure you have rpcbind running. The dtlogin-service should automatically manage this, when using dtlogin-init scripts use

```
# update-rc.d rpcbind enable
```

On a systemd system validate that the system is set to come up with a GUI by having the default  set to `graphical.target`.

```
$ systemctl get-default
multi-user.target
```

If not, change with

```
$ sudo systemctl set-default graphical.target
Removed /etc/systemd/system/default.target.
Created symlink /etc/systemd/system/default.target → /lib/systemd/system/graphical.target.
```

Then enable dtlogin, if another display manager is in use then disable that first and enable dtlogin

```
$ sudo systemctl enable dtlogin
Failed to enable unit: File /etc/systemd/system/display-manager.service already exists and is a symlink to /lib/systemd/system/lightdm.service.
$ sudo systemctl disable lightdm
Synchronizing state of lightdm.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install disable lightdm
Removed /etc/systemd/system/display-manager.service.
$ sudo systemctl enable dtlogin
Created symlink /etc/systemd/system/display-manager.service  →  /lib/systemd/system/dtlogin.service.
```

Refs: [rpi](https://sourceforge.net/p/cdesktopenv/wiki/CDE%20on%20the%20Raspberry%20Pi/) [centos](https://sourceforge.net/p/cdesktopenv/wiki/CentOSBuild/)  [init](https://sourceforge.net/p/cdesktopenv/wiki/Linux%20-%20Autostart%20dtlogin%20on%20boot/)

## Slackware

Use the [platform specific dtlogin-init](Linux/slackware/package.sh) and add the following to /etc/rc.d/rc.inet2 

```
# Start the dtlogin server:
if [ -x /etc/rc.d/rc.dtlogin ]; then
  echo "Starting Dtlogin:  /usr/dt/bin/dtlogin"
  /etc/rc.d/rc.dtlogin start
fi
```

and enable with

```
# chmod +x /etc/rc.d/rc.dtlogin
```

## FreeBSD

Ensure you have the system hostname in /etc/hosts

In **/etc/rc.conf**

```
rpcbind_enable=YES
ldconfig_paths="/usr/local/lib /usr/dt/lib"
```

You can choose to the use [dtlogin-init](FreeBSD/package.sh) package which will install the [dtlogin init script](https://sourceforge.net/p/cdesktopenv/code/ci/master/tree/cde/contrib/rc/freebsd/dtlogin). See the further configuration instructions at [FreeBSDBuild](https://sourceforge.net/p/cdesktopenv/wiki/FreeBSDBuild/#install-dtlogin-as-login-manager).

In summary, after installing the package...

```
echo 'dtlogin_enable="YES"' >> /etc/rc.conf
echo "allowed_users=anybody" > /usr/local/etc/X11/Xwrapper.config
```

## NetBSD

Ensure you have the system hostname in /etc/hosts

In **/etc/rc.conf**

```
rpcbind=YES
```

There is a [package](NetBSD/package.sh) which contains the required startup script. This requires the addition of

In **/etc/rc.conf**

```
dtlogin=YES
```

OpenBSD
---

Ensure you have the system hostname in /etc/hosts

In **/etc/rc.conf.local**

```
inetd_flags=
portmap_flags=
shlib_dirs="/usr/dt/lib"
```

And **/etc/dt/config/Xservers**

```
   :0   Local local_uid@console root  /usr/X11R6/bin/X :0
```

There is a [package](OpenBSD/package.sh) that contains the init scripts to run dtlogin at start up. When this is used, the /etc/rc.conf.local will look like:

```
inetd_flags=
portmap_flags=
xenodm_flags=NO
pkg_scripts="cmsd dtlogin"
shlib_dirs="/usr/dt/lib"
```

For further details see [OpenBSDBuild](https://sourceforge.net/p/cdesktopenv/wiki/OpenBSDBuild/).

## Solaris/SunOS/OpenIndiana

The cdesktopenv package contains a dtlogin service script

```
$ svccfg validate  /usr/dt/config/dtlogin.xml
$ sudo svccfg import /usr/dt/config/dtlogin.xml 
```

This may need a reboot.
