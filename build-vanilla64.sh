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

ID=$(date +%Y%m%d)

if [ $UID -gt 0 ]; then
  echo "Run as root!"
  exit 1
fi

rm -rf iso64 tmp64
mkdir -p tmp64 iso64/isolinux iso64/linux64/a || exit 1

if [ ! -d images64 ]; then
  mkdir images64
fi

if [ ! -d sources/slack64 ]; then
  mkdir -p sources/slack64
fi

if [ ! -d releases ]; then
  mkdir -p releases
fi

SLACK_URL=ftp://ftp.slackware.no/slackware/slackware64-14.1/slackware64/
for i in $(cat inc/SOURCES-slack64);do
  if [ ! -f sources/slack64/$i ]; then
    wget ${SLACK_URL}a/$i -O sources/slack64/$i || wget ${SLACK_URL}ap/$i -O sources/slack64/$i || wget ${SLACK_URL}d/$i -O sources/slack64/$i || wget ${SLACK_URL}l/$i -O sources/slack64/$i || wget ${SLACK_URL}n/$i -O sources/slack64/$i || wget ${SLACK_URL}x/$i -O sources/slack64/$i || exit 1
  fi
done

if [ ! -f images64/linux64.img ]; then
  wget ftp://ftp.slackware.no/slackware/slackware64-14.1/isolinux/initrd.img -O images64/linux64.img || exit 1
fi

if [ ! -f images64/bzImage64 ]; then
  wget  ftp://ftp.slackware.no/slackware/slackware64-14.1/kernels/huge.s/bzImage -O images64/bzImage64 || exit 1
fi

if [ "$1" = "download" ]; then
  exit 0
fi

cd tmp64 || exit 1
mkdir lilo || exit 1
cd lilo || exit 1
tar xvJf ../../sources/slack64/lilo-24.0-x86_64-4.txz || exit 1
cat ../../inc/liloconfig > sbin/liloconfig || exit 1
sh ../../inc/makepkg -l y -c n ../../sources/slack64/lilo-24.0-x86_64-4.txz || exit 1
cd ../../ || exit 1

cp -av inc/isolinux iso64/ || exit 1
cat inc/isolinux.slack > iso64/isolinux/isolinux.cfg || exit 1
cp -v sources/slack64/*.t*z iso64/linux64/a || exit 1
cp images64/bzImage64 iso64/isolinux/bzImage || exit 1
cat SOURCE > iso64/SOURCES || exit 1
cat EULA > iso64/EULA || exit 1
cat GPL > iso64/GPL || exit 1
rm iso64/isolinux/*grub*

cd tmp64 || exit 
mkdir initrd || exit 1
cd initrd || exit 1
zcat ../../images64/linux64.img | cpio -ivdum || exit 1
patch -p0 < ../../inc/slack.diff || exit 1
patch -p0 < ../../inc/slack64-ins.diff || exit 1
cat ../../inc/install-pkgsrc.sh > install-pkgsrc.sh || exit 1
cat ../../inc/pkgsrc-profile.sh > pkgsrc-profile.sh || exit 1
find . | cpio -co | gzip > ../../iso64/isolinux/linux.img || exit 1
cd .. || exit 1

cd ../iso64 || exit 1
cd linux64/a || exit 1
sh ../../../inc/mktag.sh || exit 1
cd ../../ || exit 1
mkisofs -o ../pkgsrc-linux64-$ID.iso -b isolinux/isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T . || exit 1
cd .. || exit 1
md5sum pkgsrc-linux64-$ID.iso > pkgsrc-linux64-$ID.iso.md5 || exit 1
sha1sum pkgsrc-linux64-$ID.iso > pkgsrc-linux64-$ID.iso.sha1 || exit 1
rm -rf iso64 tmp64 || exit 1
mv pkgsrc-linux64-$ID* releases/
