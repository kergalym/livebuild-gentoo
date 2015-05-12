#!/bin/bash

### Author: Kerimbekov Galym 
### E-mail: kerimbekov.galym@yandex.ru

BUILDROOT="/mnt/gentoo64"
ARCH="amd64"
LOOP_IMAGE="/media/WDGR/genlive64.img"
ISO_NAME="Gentoo_Linux_KDE_amd64.iso"
LIVE_IMAGE="livecd.squashfs"
#STAGE3="http://mirrors.mit.edu/gentoo-distfiles/releases/x86/autobuilds/current-stage3-i486/stage3-i686-20140826.tar.bz2"
STAGE3="http://mirrors.mit.edu/gentoo-distfiles/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-20140828.tar.bz2"
PORTS="http://distfiles.gentoo.org/snapshots/portage-20140823.tar.bz2"
REQS="'sys-fs/e2fsprogs app-cdr/cdrtools sys-fs/squashfs-tools sys-boot/syslinux'"
CHROOTPARM="chroot"
FILES="portage*.tar.bz2 stage3*.tar.bz2"

echo -e "You'll need installed $REQS to continue \n"
sleep 1

if  [ -a $pwd/.work.session ]; then
    echo "Session exist"
else 
    echo -e "Unpacking Stage3 \n"
    sleep 1
    tar xpf stage3*.tar.bz2 -C $BUILDROOT 2> $BUILDROOT/build.log
    echo -e "Unpacking Portage \n"
    sleep 1
    tar xpf portage*.tar.bz2 -C $BUILDROOT/usr 2> $BUILDROOT/buildport.log
    echo -e "Stage3 & Portage Unpacked \n" 
    sleep 1
fi

for FILES in "$pwd"
    do
    if [ -e $FILES ]; then
	echo -e "Tarballs exists. \n"
	sleep 1
	touch $pwd/.work.session
    else 
	echo -e "Downloading Stage3"
	sleep 1
	wget -c $STAGE3
	echo -e "Downloading Portage"
	sleep 1
	wget -c $PORTS
    fi
done

start() {

   echo "Mounting chroot"
   
   mount $LOOP_IMAGE $BUILDROOT
   cp -L /etc/resolv.conf $BUILDROOT/etc/
   #cp scripts/kernel-config $BUILDROOT/usr/src/linux/.config
   echo -e 'OOO_FORCE_DESKTOP=kde libreoffice --quickstart --nodefault --nologo' > $BUILDROOT/root/.kde4/Autostart/lo.sh
   chmod +x $BUILDROOT/root/.kde4/Autostart/lo.sh
   #echo -e 'OOO_FORCE_DESKTOP=kde libreoffice --quickstart --nodefault' > $BUILDROOT/etc/skel/.kde4/Autostart/lo.sh
   #chmod +x $BUILDROOT/etc/skel/.kde4/Autostart/lo.sh
   cp scripts/initrd.defaults scripts/initrd.scripts scripts/linuxrc $BUILDROOT/usr/share/genkernel/defaults/
   cp scripts/installation-helper64.sh $BUILDROOT/usr/bin/installer
   chmod +x $BUILDROOT/usr/bin/installer
   mount -t proc none $BUILDROOT/proc >/dev/null &
   mount --make-rprivate --rbind /sys $BUILDROOT/sys >/dev/null &
   mount --make-rprivate --rbind /dev $BUILDROOT/dev >/dev/null &
   chroot ${BUILDROOT} /bin/bash

}

stop() {

   echo "Unmounting chroot"

   umount $BUILDROOT/proc
   umount $BUILDROOT/sys 
   umount -l $BUILDROOT/dev{/shm,/pts,} 
   umount $LOOP_IMAGE $BUILDROOT 
}

buildroot() {

if [ -a "$LOOP_IMAGE" ]; then
    echo -e -e "Make Ext4fs on block device \n"
    sleep 1
    mkfs.ext4 $LOOP_IMAGE
else
    echo -e "Create block device \n"
    sleep 1
    dd if=/dev/zero of=$LOOP_IMAGE bs=1024K count=20000 
    echo -e "Make Ext4fs on block device \n"
    mkfs.ext4 $LOOP_IMAGE
fi

}

iso() {

    rm $ARCH/livedvd/$LIVE_IMAGE > /dev/null
    mount $LOOP_IMAGE $BUILDROOT
    cp $BUILDROOT/boot/kernel-genkernel* $ARCH/livedvd/boot/vmlinuz 
    cp $BUILDROOT/boot/initramfs-genkernel* $ARCH/livedvd/boot/initrd 
    mksquashfs $BUILDROOT $ARCH/livedvd/$LIVE_IMAGE -comp xz -e $BUILDROOT/usr/portage/distfiles -e $BUILDROOT/usr/portage/packages
    umount $LOOP_IMAGE $BUILDROOT 

if [ -a "$ISO_NAME" ]; then
    echo -e "$ISO_NAME exists! \n"
    sleep 1
    rm $ISO_NAME
    echo -e "Create ISO image"
    sleep 1
    echo -e "Gentoo" > $ARCH/livedvd/livecd
    mkisofs -R -J -o $ISO_NAME -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -iso-level 4 -boot-info-table $ARCH/livedvd/
else
    echo -e "Create ISO image \n"
    sleep 1
    echo -e "Gentoo" > $ARCH/livedvd/livecd
    mkisofs -R -J -o $ISO_NAME -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -iso-level 4 -boot-info-table $ARCH/livedvd/
    isohybrid $ISO_NAME
fi

}

usage() {
   echo "$0 [start|stop|iso|buildroot]"
}

if [ "$1" == "start" ]
then
   start
   stop
elif [ "$1" == "stop" ]
then
   stop
else
   usage
fi

if [ "$1" == "iso" ]
then
   iso
fi

if [ "$1" == "buildroot" ]
then
   buildroot
   start
   mix
   stop
fi
