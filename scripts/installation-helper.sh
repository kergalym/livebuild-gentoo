
#!/bin/bash
#
# installation-helper for GentooLive
# 01.05.2015
#
# shell script for installation of GentooLive to harddisk
#
# written by Thomas Schoenhuetl 22.05.2007
# modified for GentooLive by Galym Kerimbekov 01.05.2015
# It contains parts of the official Slackware installer.
#
# This shell script is contributed under the terms of GPL v2 by Thomas Schoenhuetl 22.05.2007.
#
mkdir /tmp/GentooLive/ 2>/dev/null
#
dialog --clear --title "ОБЩАЯ ИНФОРМАЦИЯ" --msgbox "Помощник установки GentooLive выполнит установку вашей системы \
на жесткий диск.\n\n Вы можете создавать разделы, форматировать их и установить систему, включая загрузчик.\n\n Будьте \
внимательны при разбиении жесткого диска на разделы, предварительно сохранив перед этим важные данные в надежном месте!" 20 70
if [ $? = 1 ] ; then
exit
fi
#
# umount harddisk for running cfdisk
umount /mnt/gentoo* 2>/dev/null
#
# run cfdisk to partition the harddrive
dialog --clear --title "РАЗБИЕНИЕ ЖЕСТКОГО ДИСКА" --msgbox "Помощник установки GentooLive запустит 'cfdisk', \
чтобы вы смогли создать новые разделы для системы.\n\n Рекомендуется создать два раздела. 1 под систему (не менее 15 ГБ) \
и  2 для раздела подкачки.\n\n Проследуйте дальше и выполните необходимые операции, а затем примените их и выйдите из \
программы 'cfdisk'\n\n ВАЖНО!: внимательно прочтите инструкции и вывод cfdisk. В некоторых случаях необходимо перезагрузить \
компьютер, чтобы обновить таблицу разделов! Выйдите из cfdisk если разделы уже существуют" 20 70
if [ $? = 1 ] ; then
exit
fi

# Create partitions using fdisk or cfdisk.

mkdir /tmp/tmp 2>/dev/null
TMP=/tmp/tmp 2>/dev/null

fdisk -l | sed -n 's/^Disk \(\/dev\/[^:]*\): \([^,]*\).*$/"\1" "\2" \\/p' >> $TMP/drivelist

while [ 0 ]; do
echo dialog --ok-label Select \
--cancel-label Continue \
--title \"PARTITIONING\" \
--menu \"Select drive to partition:\" 11 40 4 \\\
> $TMP/tmpscript
cat $TMP/drivelist >> $TMP/tmpscript
echo "2> $TMP/tmpanswer" >> $TMP/tmpscript
. $TMP/tmpscript
[ $? != 0 ] && break
PARTITION=`cat $TMP/tmpanswer`

if [ ! -f /etc/expert-mode ]; then
cfdisk $PARTITION
else
echo dialog --title \"PARTITIONING $PARTITION\" \
--menu \"Select which fdisk program you want to use. cfdisk is \
strongly recommended for newbies while advanced users may prefer fdisk.\" \
11 50 2 \
cfdisk \"Curses based partitioning program\" \
fdisk \"Traditional fdisk\" \
"2> $TMP/tmpanswer" > $TMP/tmpscript
. $TMP/tmpscript
[ $? != 0 ] && continue
FDISKPROGRAM=`cat $TMP/tmpanswer`
clear
if [ "$FDISKPROGRAM" = "cfdisk" ]; then
cfdisk $PARTITION
elif [ "$FDISKPROGRAM" = "fdisk" ]; then
fdisk $PARTITION
fi
fi
done

rm -f $TMP/drivelist $TMP/tmpscript $TMP/tmpanswer

TMP=/tmp/tmp
if [ ! -d $TMP ]; then
mkdir -p $TMP
fi
REDIR=/dev/tty4
NDIR=/dev/null
crunch() {
read STRING;
echo $STRING;
}
rm -f $TMP/SeTswap $TMP/SeTswapskip
SWAPLIST="`fdisk -l | fgrep "Linux swap" | sort 2> $NDIR`"
if [ "$SWAPLIST" = "" ]; then
dialog --title "РАЗДЕЛ ПОДКАЧКИ НЕ ОБНАРУЖЕН" --yesno "Вы не создали раздел подкачки Linux с помощью fdisk. \
Хотите продолжить установку без него? " 6 60
if [ "$?" = "1" ]; then
dialog --title "ПРЕКРАЩЕНИЕ УСТАНОВКИ" --msgbox "Создайте раздел подкачки Linux с помощью fdisk и попробуйте снова." 6 40
exit 1
else
exit 0
fi
else # there is at least one swap partition:
echo > $TMP/swapmsg
if [ "`echo "$SWAPLIST" | sed -n '2 p'`" = "" ]; then
echo "Помощник установки GentooLive обнаружил раздел подкачки:\n\n" >> $TMP/swapmsg
echo >> $TMP/swapmsg
echo " Device Boot Start End Blocks Id System\\n" >> $TMP/swapmsg
echo "`echo "$SWAPLIST" | sed -n '1 p'`\\n\n" >> $TMP/swapmsg
echo >> $TMP/swapmsg
echo "Хотите создать этот раздел в качестве раздела подкачки?" >> $TMP/swapmsg
dialog --title "РАЗДЕЛ ПОДКАЧКИ ОБНАРУЖЕН" --cr-wrap --yesno "`cat $TMP/swapmsg`" 12 72
REPLY=$?
else
echo "Помощник установки GentooLive обнаружил следующие разделы подкачки:" >> $TMP/swapmsg
echo >> $TMP/swapmsg
echo " Device Boot Start End Blocks Id System\\n" >> $TMP/swapmsg
echo "$SWAPLIST\\n\n" >> $TMP/swapmsg
echo >> $TMP/swapmsg
echo "Хотите создать эти разделы в качестве разделов подкачки? " >> $TMP/swapmsg
dialog --title "РАЗДЕЛЫ ПОДКАЧКИ ОБНАРУЖЕНЫ" --cr-wrap --yesno "`cat $TMP/swapmsg`" 13 72
REPLY=$?
fi
rm -f $TMP/swapmsg
if [ $REPLY = 0 ]; then # yes
if grep "SwapTotal: * 0 kB" /proc/meminfo 1> $NDIR 2> $NDIR ; then
USE_SWAP=0 # swap is not currently mounted
else # warn of possible problems:
# This 10231808 below is the size of a swapfile pre-supplied by install.zip that we'd like to ignore.
if grep 10231808 /proc/meminfo 1> $NDIR 2> $NDIR ; then
USE_SWAP=0
else
cat $TMP/swapmsg
IMPORTANT NOTE: If you have already made any of your swap
partitions active "(using the swapon command)", then you
should not allow Setup to use mkswap on your swap partitions,
because it may corrupt memory pages that are currently
swapped out. Instead, you will have to make sure that your
swap partitions have been prepared "(with mkswap)" before they
will work. You might want to do this to any inactive swap
partitions before you reboot.
EOF
dialog --title "MKSWAP WARNING" --msgbox "`cat $TMP/swapmsg`" 12 67
rm -f $TMP/swapmsg
dialog --title "ИСПОЛЬЗОВАТЬ MKSWAP?" --yesno "Вы хотите применить mkswap к пространству подкачки?" \
5 65
USE_SWAP=$?
fi
fi
CURRENT_SWAP="1"
while [ ! "`echo "$SWAPLIST" | sed -n "$CURRENT_SWAP p"`" = "" ]; do
SWAP_PART=`fdisk -l | fgrep "Linux swap" | sed -n "$CURRENT_SWAP p" | crunch | cut -f 1 -d ' '`
if [ $USE_SWAP = 0 ]; then
dialog --title "ФОРМАТИРОВАНИЕ РАЗДЕЛА ПОДКАЧКИ" --infobox "Форматирование \
$SWAP_PART в раздел подкачки Linux (и проверка на наличие битых секторов)..." 4 55
mkswap -c $SWAP_PART 1> $REDIR 2> $REDIR
fi
echo "Активация раздела подкачки $SWAP_PART:"
echo "swapon $SWAP_PART"
swapon $SWAP_PART 1> $REDIR 2> $REDIR
#SWAP_IN_USE="`echo "$SWAP_PART swap swap defaults 0 0"`"
#echo "$SWAP_IN_USE" >> $TMP/SeTswap
printf "%-11s %-11s %-11s %-27s %-2s %s\n" "$SWAP_PART" "swap" "swap" "defaults" "0" "0" >> $TMP/SeTswap
CURRENT_SWAP="`expr $CURRENT_SWAP + 1`"
sleep 1
done
echo "пространство подкачки настроено. Эти сведения будут внесены" > $TMP/swapmsg
echo "в  /etc/fstab:" >> $TMP/swapmsg
echo >> $TMP/swapmsg
cat $TMP/SeTswap >> $TMP/swapmsg
dialog --title "ПРОСТРАНСТВО ПОДКАЧКИ НАСТРОЕНО" --exit-label OK --textbox $TMP/swapmsg 10 72
cat $TMP/SeTswap > $TMP/SeTfstab
rm -f $TMP/swapmsg $TMP/SeTswap
fi
fi

# format root partition
fdisk -l | grep Linux | sed -e '/swap/d' | cut -b 1-10 > $TMP/pout 2>/dev/null

dialog --clear --title "ОБНАРУЖЕН КОРНЕВОЙ РАЗДЕЛ" --exit-label OK --msgbox "Помощник установки GentooLive обнаружил \n\n `cat /tmp/tmp/pout` \n\n в качестве Linux-совместимого \
раздела(ов).\n\n Далее можно выбрать файловую систему  для корневого раздела из нескольких, если таковые имеются!" 20 70
if [ $? = 1 ] ; then
exit
fi

# choose root partition
dialog --clear --title "ВЫБЕРИТЕ КОРНЕВОЙ РАЗДЕЛ" --inputbox "Укажите предпочитаемый раздел:\n\n введите /dev/sdaX --- где X - номер раздела, \
например 1 для /dev/sda1!" 10 70 2> $TMP/pout

dialog --clear --title "ОТФОРМАТИРУЙТЕ КОРНЕВОЙ РАЗДЕЛ" --radiolist "Теперь можно выбрать файловую систему для корневого раздела; имейте ввиду, \
что раздел будет отформатирован после выбора файловой системы." 10 70 0 \
"1" "ext2" off \
"2" "ext3" off \
"3" "ext4" on \
"4" "reiserfs" off \
"5" "btrfs" off \
2> $TMP/part
if [ $? = 1 ] ; then
exit
fi

if [ `cat $TMP/part` = "1" ] ; then
mkfs.ext2 `cat $TMP/pout`
dialog --clear --title "ОТФОРМАТИРУЙТЕ КОРНЕВОЙ РАЗДЕЛ" --msgbox "Теперь раздел будет отформатирован в файловую систему ext2." 10 70
echo "`cat $TMP/pout` / ext2 defaults,noatime 1 1" >> $TMP/SeTfstab2
# mount the root partition to copy the system
mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`
mount -t ext2 /dev/`cat $TMP/pout | cut -b 6-10` /mnt//gentoo/`cat $TMP/pout | cut -b 6-10`
fi

if [ `cat $TMP/part` = "2" ] ; then
mkfs.ext3 `cat $TMP/pout`
dialog --clear --title "ОТФОРМАТИРУЙТЕ КОРНЕВОЙ РАЗДЕЛ" --msgbox "Теперь раздел будет отформатирован в файловую систему ext3." 10 70
echo "`cat $TMP/pout` / ext3 defaults,noatime 1 1" >> $TMP/SeTfstab2
# mount the root partition to copy the system
mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`
mount -t ext3 /dev/`cat $TMP/pout | cut -b 6-10` /mnt//gentoo/`cat $TMP/pout | cut -b 6-10`
fi

if [ `cat $TMP/part` = "3" ] ; then
mkfs.ext4 `cat $TMP/pout`
dialog --clear --title "ОТФОРМАТИРУЙТЕ КОРНЕВОЙ РАЗДЕЛ" --msgbox "Теперь раздел будет отформатирован в файловую систему ext4." 10 70
echo "`cat $TMP/pout` / ext4 defaults,noatime 1 1" >> $TMP/SeTfstab2
# mount the root partition to copy the system
mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`
mount -t ext4 /dev/`cat $TMP/pout | cut -b 6-10` /mnt//gentoo/`cat $TMP/pout | cut -b 6-10`
fi

if [ `cat $TMP/part` = "4" ] ; then
mkfs.reiserfs -f `cat $TMP/pout`
dialog --clear --title "ОТФОРМАТИРУЙТЕ КОРНЕВОЙ РАЗДЕЛ" --msgbox "Теперь раздел будет отформатирован в файловую систему reiserfs." 10 70
echo "`cat $TMP/pout` / reiserfs defaults,noatime 1 1" >> $TMP/SeTfstab2
# mount the root partition to copy the system
mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`
mount -t reiserfs /dev/`cat $TMP/pout | cut -b 6-10` /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`
fi

if [ `cat $TMP/part` = "5" ] ; then
mkfs.btrfs -f `cat $TMP/pout`
dialog --clear --title "ОТФОРМАТИРУЙТЕ КОРНЕВОЙ РАЗДЕЛ" --msgbox "Теперь раздел будет отформатирован в файловую систему btrfs." 10 70
echo "`cat $TMP/pout` / btrfs defaults,noatime 1 1" >> $TMP/SeTfstab2
# mount the root partition to copy the system
mkdir /mnt/gentoo/gentoo/`cat $TMP/pout | cut -b 6-10`
mount -t btrfs /dev/`cat $TMP/pout | cut -b 6-10` /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`
fi
# copy the system
dialog --clear --title "КОПИРОВАНИЕ ФАЙЛОВ СИСТЕМЫ" --msgbox "Помощник установки GentooLive начнет копирование файлов системы на жесткий диск.\n\n Нажмите OK \
чтобы начать ..." 10 70
if [ $? = 1 ] ; then
exit
fi

dialog --title "ПРОЦЕСС КОПИРОВАНИЯ" --infobox "Помощник установки GentooLive копирует файлы системы на жесткий диск.\n\n Пожалуйста подождите ... это может занять \
до 10 минут в зависимости от вашей системы!" 10 70

cp -arpx /mnt/livecd/{boot,bin,dev,home,etc,lib,media,mnt,opt,proc,root,run,sbin,sys,var,usr,tmp} /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/ 2>/dev/null

mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/mnt 2>/dev/null
mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/media 2>/dev/null
mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/proc 2>/dev/null
mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/sys 2>/dev/null
mkdir /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/tmp 2>/dev/null

dialog --clear --title "ОПЕРАЦИЯ ЗАВЕРШЕНА" --msgbox "Помощник установки GentooLive завершил операцию копирования." 10 70
if [ $? = 1 ] ; then
exit
fi

# create new fstab
echo `cat $TMP/SeTfstab` > /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/etc/fstab 2>/dev/null
echo `cat $TMP/SeTfstab2` >> /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/etc/fstab 2>/dev/null

# prepare installation of Grub2
mount --bind /dev /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/dev
mount -t proc /proc /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/proc

# install Grub2 with or without Windows
dialog --clear --title "УСТАНОВКА СИСТЕМНОГО ЗАГРУЗЧИКА" --radiolist "Выберите раздел для установки системного загрузчика." 10 70 0 \
"1" "GRUB2 Loader" on \
2> $TMP/part
if [ $? = 1 ] ; then
exit
fi

if [ `cat $TMP/part` = "1" ] ; then
#mkdir -p /mnt/gentoo/`cat $TMP
#cat $TMP/pout >  /mnt/gentoo/`cat $TMP/pout
/usr/sbin/grub2-install --root-directory=/mnt/gentoo/`cat $TMP/pout | cut -b 6-10`  `cat $TMP/pout | cut -b 1-8` 
chroot /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`  /bin/bash -c '/usr/sbin/grub2-mkconfig -o /boot/grub/grub.cfg'

dialog --clear --title "УСТАНОВКА ЗАВЕРШЕНА" --msgbox "Помощник установки GentooLive завершил установку.\n\n Перезагрузите компьютер." 10 70
if [ $? = 1 ] ; then
exit
fi
fi

umount  /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/{proc,dev}  2>/dev/null
umount  /mnt/gentoo/`cat $TMP/pout | cut -b 6-10`/ 2>/dev/null


rm -R $TMP

exit