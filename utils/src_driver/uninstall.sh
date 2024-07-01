# Uninstall MSR driver
rm -f /dev/MSRdrv
rmmod MSRdrv
# modprobe -r MSRdrv

MODULEDIR=/lib/modules/`uname -r`/extra
rm -rf $MODULEDIR
depmod -a