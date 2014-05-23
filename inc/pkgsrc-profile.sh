#!/bin/sh

if [ $UID -gt 0 ]; then
  export PATH=$PATH:/usr/pkg/bin
else
  export PATH=$PATH:/usr/pkg/bin:/usr/pkg/sbin
fi
export MANPATH=$MANPATH:/usr/pkg/man
