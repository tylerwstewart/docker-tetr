#!/bin/sh

DOCKER_IMAGE="cmoye/tc-imager:7.2-x86-2"
DOCKER_VOLUMES="--volumes-from tc-src -v $HOME/tc-deliver:/home/tc/tc-deliver:rw"
DOCKER_ENVS="-e TCMIRROR=http://pecan.digium.internal:81/tinycore-testing/"

DOCKER_ARGS="$DOCKER_VOLUMES $DOCKER_ENVS $DOCKER_IMAGE"

# For python script to handle using Docker.io for building and remastering
# https://wiki.python.org/moin/PortingToPy3k/BilingualQuickRef
#~ from __future__ import absolute_import, division, print_function, unicode_literals
# http://python-future.org/compatible_idioms.html
# Python 2.7+ and 3.3+
# Python 2 and 3 (after ``pip install configparser``):
#~ from configparser import ConfigParser
# Python 2.7 and above
#~ from collections import Counter, OrderedDict

exerr() {
  printf $@
  [ ! -z "$pkg" ] && cat<<EOF

To troubleshoot this failed tet build of $pkg:
  docker run -it --entrypoint sh $DOCKER_ARGS --login
    cd ~/tc-ext-tools/packages/$pkg
    buildit

EOF
  [ ! -z "$REMASTER" ] && cat<<EOF

To troubleshoot this failed remaster of $1:
  docker run -it --entrypoint sh $DOCKER_ARGS --login
    tc-diskless-remaster -n $@

EOF
  exit 1
}

docker_shell() {
  docker run -it --entrypoint sh $DOCKER_ARGS $@
}

build_packages() {
  for pkg in $@; do
    docker run $DOCKER_ARGS tet $pkg || exerr "Error building package $pkg";
  done
}

test_extensions() {
  for pkg in $@; do
    docker run $DOCKER_ARGS tettest $pkg || exerr "Error testing package $pkg";
  done
}

remaster() {
  REMASTER=1
  docker run $DOCKER_ARGS $@ || exerr "Error bundling remastered image for $1";
}
