FROM tatsushid/tinycore:7.2-x86
# Instructions are run with 'tc' user

# <local TC mirror> = http://pecan.digium.internal:81/tinycore-testing/
# docker build --build-arg TCMIRROR=<local TC mirror> -t chazzam/tetr:7.2-x86 -t chazzam/tetr:latest .
# docker run -e TCMIRROR=<local TC mirror> -v $HOME/tc-deliver:/home/tc/tc-deliver:rw chazzam/tetr:7.2-x86
ARG TCMIRROR
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV TCUSER="tc" LANG=C.UTF-8 LC_ALL=C LANGUAGE=C.UTF-8 \
    CFLAGS="-m32 -march=i486 -mtune=i686 -Os -pipe" \
    CXXFLAGS="-m32 -march=i486 -mtune=i686 -Os -pipe" \
    LDFLAGS="-m32 -Wl,-O1" \
    CC="gcc -flto -fuse-linker-plugin" \
    CXX="g++ -flto -fuse-linker-plugin" \
    TCDELIVER="tc-deliver"

# Because docker is insane and sets its own owner:group instead of anything sane
# like using the USER from Dockerfile, or copying the owner:group as-is,
# we'll use sudo to fix permissions instead of wasting image layers
COPY uname tc-imager-build.sh git-clones.sh /home/$TCUSER/.local/bin/
COPY config /home/$TCUSER/.ssh/

# These commands require DNS to be setup correctly on the Docker host machine.
# Your '/etc/resolv.conf' file needs to have entries for nameserver that are not localhost
# addresses, and that can resolve external connections, your TCMIRROR at a minimum

WORKDIR /home/$TCUSER

RUN sudo chown -R $TCUSER:staff /home/$TCUSER && \
    . .ashrc .profile && \
    chmod 0600 -R /home/$TCUSER/.ssh/* && \
    chmod 0700 /home/$TCUSER/.ssh && \
    echo etc/init.d/tet-functions >> /opt/.filetool.lst && \
    mkdir -p /home/$TCUSER/$TCDELIVER/packages /home/$TCUSER/$TCDELIVER/remaster && \
    ( [ ! -z "$TCMIRROR" ] && echo "$TCMIRROR" > /opt/tcemirror||true) && \
    tce-load -wic \
        advcomp.tcz \
        autoconf.tcz \
        automake.tcz \
        compiletc.tcz \
        expat2.tcz \
        gettext.tcz \
        git.tcz \
        libtool-dev.tcz \
        perl_xml_parser.tcz \
        squashfs-tools.tcz \
        tar.tcz \
        wget.tcz \
        xz.tcz \
        zsync.tcz \
      && \
    ~/.local/bin/git-clones.sh && \
    ~/.local/bin/update-tet-database
    #~ ( tce-load -w python3.5 || true; )

ENTRYPOINT [".local/bin/tc-imager-build.sh"]
