Gentoo LiveBuild Scripts 
===

These scripts are semi-automated and designed to create and modify custom Gentoo-based LiveSystem (from stage3) that can be burned to DVD or recorded to Flash Drive

Don't hesitate to adjust them for youself

## Usage:

Running buildsysio.sh without any argument shows list of exist arguments, here they are:

start: chrooting into exist system to made changes
stop: umounts exist chroot session
iso: packing live system into squashfs image and then create iso image
buildroot: create live system from scratch (from stage3)

### Installing

Please read https://wiki.gentoo.org/wiki/Layman for more information regarding layman.

### Add it using layman:

      layman -f -o https://raw.githubusercontent.com/kergalym/livebuild-gentoo/master/repositories.xml -a livebuild-gentoo

### Add it manually :

      cd /var/lib/layman
      git clone https://github.com/kergalym/livebuild-gentoo.git

then add it to your make.conf


