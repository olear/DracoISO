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

rm -rf iso64 tmp64
mkdir -p tmp64 iso64/isolinux iso64/images iso64/linux64 || exit 1

if [ ! -d images64 ]; then
  mkdir images64
fi

if [ ! -d sources/el64 ]; then
  mkdir -p sources/el64
fi

if [ ! -d releases ]; then
  mkdir -p releases
fi

for i in $(cat inc/SOURCES-images64);do
  URL=$(echo $i|sed 's/|/ /'|awk '{print $1}')
  FILE=$(echo $i|sed 's/|/ /'|awk '{print $2}')
  if [ ! -f images64/$FILE ]; then
    wget ${URL}$FILE -O images64/$FILE || exit 1
  fi
done

EL_URL=ftp://ftp.slackware.no/centos/6.5/os/x86_64/Packages/
EL_URL2=ftp://ftp.slackware.no/centos/6.5/updates/x86_64/Packages/
for y in $(cat inc/SOURCES-pkg*);do
  if [ ! -f sources/el64/$y ]; then
    wget ${EL_URL}$y -O sources/el64/$y || wget ${EL_URL2}$y -O sources/el64/$y || exit 1
  fi
done

DL_URL=http://sourceforge.net/projects/dracolinux/files/el6/x86_64/
for x in $(cat inc/SOURCES-draco);do
  if [ ! -f sources/$x ]; then
    wget ${DL_URL}${x}/download -O sources/el64/$x || exit 1
  fi
done

if [ "$1" = "download" ]; then
  exit 0
fi

cp -av inc/isolinux iso64/ || exit 1
cp -v sources/el64/*.rpm iso64/linux64/ || exit 1
cat SOURCE > iso64/SOURCES || exit 1
cat EULA > iso64/EULA || exit 1
cat GPL > iso64/GPL || exit 1
cat inc/comps.xml > iso64/comps.xml || exit 1
cat inc/discinfo > iso64/.discinfo || exit 1
cat inc/treeinfo > iso64/.treeinfo || exit 1
cat inc/ks.cfg > iso64/ks.cfg || exit 1
cp images64/vmlinuz iso64/isolinux/ || exit 1

cd tmp64 || exit 1
mkdir initrd || exit 1
cd initrd || exit 1
cat ../../images64/initrd.img | unlzma | cpio -ivdum || exit 1
cat ../../inc/version > .buildstamp || exit 1
find . | cpio -co | lzma > ../../iso64/isolinux/initrd.img || exit 1
cd .. || exit 1

unsquashfs ../images64/install.img || exit 1
cd squashfs-root || exit 1
cp ../../inc/install/*.png usr/share/anaconda/pixmaps/ || exit 1
cat ../../inc/install/gtkrc > usr/share/themes/Slider/gtk-2.0/gtkrc || exit 1
cat ../../inc/install/kickstart.py > usr/lib/anaconda/kickstart.py || exit 1
mksquashfs . ../../iso64/images/install.img || exit 1
cd .. || exit 1

cd ../iso64 || exit 1
createrepo -g comps.xml . || exit 1
mkisofs -o ../$N-$ID-$V-$B.iso -b isolinux/isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T . || exit 1
cd .. || exit 1
md5sum $N-$ID-$V-$B.iso > $N-$ID-$V-$B.iso.md5 || exit 1
sha1sum $N-$ID-$V-$B.iso > $N-$ID-$V-$B.iso.sha1 || exit 1
rm -rf iso64 tmp64 || exit 1

