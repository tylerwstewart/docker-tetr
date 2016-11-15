#! /bin/sh

# tet <package>
# <image config> # for tc-diskless-remaster

TCUSER=`cat /etc/sysconfig/tcuser`
TCHOME="/home/$TCUSER"
TCSOURCE="$TCHOME/src"
TCBIN="$TCHOME/.local/bin"
TET="$TCHOME/tc-ext-tools"
TETPKG="$TET/packages"
TETSTORE="$TET/storage"
DELIVER="$TCHOME/tc-deliver"
REMASTER="$DELIVER/remaster"
PACKAGES="$DELIVER/packages"
SUBMITS="$DELIVER/submits"

exerr() {
  printf $@
  exit 1
}

verify_git() {
  $TCBIN/git-clones.sh git
}

update_git() {
  # Make sure git repo's are up to date
  #~ (cd ${TCSOURCE}/;
  local d;
    for d in $(find $TCSOURCE/* -maxdepth 0 -type d); do
      ( cd $d;
        [ -d .git ] && printf "%s: " ${d##$TCSOURCE/} && git pull;
      );
    done;
  #~ )
}

update_packages() {
  local d;
  for d in $(find $TCSOURCE/* -maxdepth 0 -type d); do
    local git_pkgs="$d/packages"
    [ -d $git_pkgs ] || continue
    # symlink the packages into the tc-ext-tools directory
    ln -s $git_pkgs/* $TETPKG/ 2>/dev/null;
    ln -s $(find $d -maxdepth 1 -type f -executable) $TET/ 2>/dev/null
  done
}

tet() {
  # build the requested package(s)
  cd ${TETPKG}/ || exerr "No TET packages available"
  ${TCBIN}/update-tet-database || exerr "No TET database"
  ${TCBIN}/buildit $1 || exerr "Couldn't build TET package"
  PACKAGES_DIR="$PACKAGES/$PACKAGE_SUBDIR"
  SUBMITS_DIR="$SUBMITS/$PACKAGE_SUBDIR"
  [ -d "${PACKAGES_DIR}" ] || \
    sudo mkdir -p "${PACKAGES_DIR}" || \
    exerr "Couldn't make packages directory"
  [ -d "${SUBMITS_DIR}" ] || \
    sudo mkdir -p "${SUBMITS_DIR}" || \
    exerr "Couldn't make Submittables directory"
  sudo chown -R $TCUSER:staff ${DELIVER}
  sudo chmod -R u+rwX,g+rwX,o+rwX ${DELIVER}

  # Copy packages to src volume
  sudo cp -fLap ${TETSTORE}/*/pkg/*/*.tcz* ${PACKAGES_DIR}/|| exerr "Couldn't copy package deliverables"
  sudo cp -fLap ${TETSTORE}/*/pkg/*.bfe ${SUBMITS_DIR}/
}

tetiff() {
  . /etc/init.d/tet-functions
  tetinfo $1 >/dev/null 2>&1
  [ "$?" -eq "0" ] && tet $1
}

tettest() {
  [ -d $PACKAGES/PACKAGE_SUBDIR ] || exerr "No built packages"
  . /etc/init.d/tet-functions
  tetinfo $1 >/tmp/info.txt || exerr "Couldn't find package $1"
  (
    . /tmp/info.txt;
    cd $PACKAGES/PACKAGE_SUBDIR;
    for e in $EXTENSIONS; do
      EXTS="$EXTS $(find -name ${e}.tcz)";
    done;
    tce-load -ic $EXTS || exerr "Couldn't load extensions from $1";
  )
  exit $?
}

tc_remaster() {
  [ -d "${REMASTER}/" ] || mkdir -p "${REMASTER}/" || exerr "Couldn't make remaster directory"
  TC_PYTHON_35="python3.5.tcz"
  if [ "$TC_VER" -lt "7" ]; then
    tet python3.5
  fi
  tce-load -ic python3.5 || exerr "Couldn't load Python 3.5"
  [ -f /usr/local/bin/python3 ] || ln -s $(which python3.5) /usr/local/bin/python3
  CONFIG=$(find $REMASTER -name $1|head -n1)
  shift;
  sudo ${TCBIN}/tc-diskless-remaster $CONFIG \
    -t $TC_VER -a $TC_ARCH -k "$(uname -r)" \
    -o $REMASTER/ -m $TCMIRROR -e $PACKAGES/ $@ ||\
    exerr "Couldn't create remastered image(s)"
}

TC_VER=$(. /etc/init.d/tc-functions; getMajorVer)
TC_ARCH=$(file -b /bin/busybox|cut -d, -f1|egrep -o [0-9]{2})
[ -z "$TC_VER" ] && exerr "No TC Major Version"
[ -z "$TC_ARCH" ] && exerr "No TC Arch"
[ "$TC_ARCH" = "32" ] && TC_ARCH="x86"
[ "$TC_ARCH" = "64" ] && TC_ARCH="x86_64"
PACKAGE_SUBDIR="${TC_VER}.x/$TC_ARCH/tcz"

verify_git;

. ${TCHOME}/.profile
[ ! -z "$TCMIRROR" ] && echo "$TCMIRROR" > /opt/tcemirror
if [ "$1" = "git" ]; then
  update_git;
  shift;
fi
update_packages;
if [ "$1" = "tet" ]; then
  shift;
  tet $@
elif [ "$1" = "tetiff" ]; then
  shift;
  tetiff $@
elif [ "$1" = "tettest" ]; then
  shift;
  tettest $@
else
  tc_remaster $@
fi;
