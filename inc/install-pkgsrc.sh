#!/bin/sh

# Setup pkgsrc on Linux

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

# Download and extract pkgsrc
if [ ! -f pkgsrc.tar.xz ]; then
  wget ftp://ftp.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.xz || exit 1
fi
tar xvf pkgsrc.tar.xz -C /usr || exit 1

# Bootstrap
cat <<EOF > /usr/pkgsrc/bootstrap/mk-fragment.conf
FAILOVER_FETCH=	yes
X11_TYPE= modular
SKIP_LICENSE_CHECK= yes
ALLOW_VULNERABLE_PACKAGES= yes

PKG_DEVELOPER?= no
MAKE_JOBS=4
EOF

cd /usr/pkgsrc/bootstrap || exit 1
./bootstrap --prefer-pkgsrc=yes --mk-fragment /usr/pkgsrc/bootstrap/mk-fragment.conf
