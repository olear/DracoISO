#!/bin/sh

# Copyright 2014 Ole Andre Rodlie <olear@dracolinux.org> 
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

B=$(sed -n '1'p inc/version)
N=$(sed -n '2'p inc/version)
V=$(sed -n '3'p inc/version)
DATE=$(date +%Y%m%d)
ID=preview-$DATE

if [ $UID -gt 0 ]; then
  echo "Run as root!"
  exit 1
fi

rm -rf iso tmp
mkdir -p tmp iso/isolinux iso/images iso/centos iso/slackware64/a || exit 1

if [ ! -d images ]; then
  mkdir images
fi

if [ ! -d sources ]; then
  mkdir sources
fi

for i in $(cat inc/SOURCES-images);do
  URL=$(echo $i|sed 's/|/ /'|awk '{print $1}')
  FILE=$(echo $i|sed 's/|/ /'|awk '{print $2}')
  if [ ! -f images/$FILE ]; then
    wget ${URL}$FILE -O images/$FILE || exit 1
  fi
done

SLACK_URL=ftp://ftp.slackware.no/slackware/slackware64-14.1/slackware64/
for i in $(cat inc/SOURCES-slack);do
  if [ ! -f sources/$i ]; then
    wget ${SLACK_URL}a/$i -O sources/$i || wget ${SLACK_URL}ap/$i -O sources/$i || wget ${SLACK_URL}d/$i -O sources/$i || wget ${SLACK_URL}l/$i -O sources/$i || wget ${SLACK_URL}n/$i -O sources/$i || wget ${SLACK_URL}x/$i -O sources/$i || exit 1
  fi
done

if [ ! -f images/diy.img ]; then
  wget ftp://ftp.slackware.no/slackware/slackware64-14.1/isolinux/initrd.img -O images/diy.img || exit 1
fi

if [ ! -f images/bzImage ]; then
  wget  ftp://ftp.slackware.no/slackware/slackware64-14.1/kernels/huge.s/bzImage -O images/bzImage || exit 1
fi

EL_URL=ftp://ftp.slackware.no/centos/6.5/os/x86_64/Packages/
EL_URL2=ftp://ftp.slackware.no/centos/6.5/updates/x86_64/Packages/
for y in $(cat inc/SOURCES-pkg*);do
  if [ ! -f sources/$y ]; then
    wget ${EL_URL}$y -O sources/$y || wget ${EL_URL2}$y -O sources/$y || exit 1
  fi
done

DL_URL=http://sourceforge.net/projects/dracolinux/files/el6/x86_64/
for x in $(cat inc/SOURCES-draco);do
  if [ ! -f sources/$x ]; then
    wget ${DL_URL}${x}/download -O sources/$x || exit 1
  fi
done

if [ "$1" = "download" ]; then
  exit 0
fi

cd tmp || exit 1
mkdir lilo || exit 1
cd lilo || exit 1
tar xvJf ../../sources/lilo-24.0-x86_64-4.txz || exit 1
cat ../../inc/liloconfig > sbin/liloconfig || exit 1
sh ../../inc/makepkg -l y -c n ../../sources/lilo-24.0-x86_64-4.txz || exit 1
cd ../../ || exit 1

cp -av inc/isolinux iso/ || exit 1
cp -v sources/*.rpm iso/centos/ || exit 1
cp -v sources/*.t*z iso/slackware64/a || exit 1
cat SOURCE > iso/SOURCES || exit 1
cat EULA > iso/EULA || exit 1
cat GPL > iso/GPL || exit 1
cat inc/comps.xml > iso/comps.xml || exit 1
cat inc/discinfo > iso/.discinfo || exit 1
cat inc/treeinfo > iso/.treeinfo || exit 1
cat inc/ks.cfg > iso/ks.cfg || exit 1
cp images/vmlinuz iso/isolinux/ || exit 1
cp images/bzImage iso/isolinux/ || exit 1
cp images/diy.img iso/isolinux/ || exit 1

cd tmp || exit 1
mkdir initrd || exit 1
cd initrd || exit 1
cat ../../images/initrd.img | unlzma | cpio -ivdum || exit 1
cat ../../inc/version > .buildstamp || exit 1
find . | cpio -co | lzma > ../../iso/isolinux/initrd.img || exit 1
cd .. || exit 1

mkdir slack
cd slack || exit 1
zcat ../../images/diy.img | cpio -ivdum || exit 1
patch -p0 < ../../inc/slack.diff || exit 1
cat ../../inc/install-pkgsrc.sh > install-pkgsrc.sh || exit 1
cat ../../inc/pkgsrc-profile.sh > pkgsrc-profile.sh || exit 1
find . | cpio -co | gzip > ../../iso/isolinux/diy.img || exit 1
cd .. || exit 1

unsquashfs ../images/install.img || exit 1
cd squashfs-root || exit 1
cp ../../inc/install/*.png usr/share/anaconda/pixmaps/ || exit 1
cat ../../inc/install/gtkrc > usr/share/themes/Slider/gtk-2.0/gtkrc || exit 1
cat ../../inc/install/kickstart.py > usr/lib/anaconda/kickstart.py || exit 1
mksquashfs . ../../iso/images/install.img || exit 1
cd .. || exit 1

cd ../iso || exit 1
cd slackware64/a || exit 1
sh ../../../inc/mktag.sh || exit 1
cd ../../ || exit 1
createrepo -g comps.xml . || exit 1
mkisofs -o ../$N-$ID-$V-$B.iso -b isolinux/isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T . || exit 1
cd .. || exit 1
md5sum $N-$ID-$V-$B.iso > $N-$ID-$V-$B.iso.md5 || exit 1
sha1sum $N-$ID-$V-$B.iso > $N-$ID-$V-$B.iso.sha1 || exit 1
rm -rf iso tmp || exit 1

