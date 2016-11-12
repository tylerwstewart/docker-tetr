FROM tatsushid/tinycore:7.2-x86_64
# Instructions are run with 'tc' user

# <local TC mirror> = http://pecan.digium.internal:81/tinycore-testing/
# docker build --build-arg TCMIRROR=<local TC mirror> -t chazzam/tetr:7.2-x86_64 -t chazzam/tetr:latest-x86_64 .
# docker run -e TCMIRROR=<local TC mirror> -v $HOME/tc-deliver:/home/tc/tc-deliver:rw chazzam/tetr:7.2-x86_64

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV TCUSER="tc" LANG=C.UTF-8 LC_ALL=C LANGUAGE=C.UTF-8 \
    CFLAGS="-mtune=generic -Os -pipe" \
    CXXFLAGS="-mtune=generic -Os -pipe" \
    LDFLAGS="-Wl,-O1" \
    CC="gcc -flto -fuse-linker-plugin" \
    CXX="g++ -flto -fuse-linker-plugin" \
    TCDELIVER="tc-deliver"

USER root
# Setup backup of tet-functions, and users home directory
COPY uname tc-imager-build.sh git-clones.sh /home/$TCUSER/.local/bin/
COPY config /home/$TCUSER/.ssh/
RUN echo "$TCUSER" > /etc/sysconfig/tcuser && \
    sed -i -e 's/ -le 3 \]$/ -le 6 ]/;' /etc/init.d/tc-functions && \
    . /etc/init.d/tc-functions && \
    mkdir -p /home/$TCUSER/$TCDELIVER/packages /home/$TCUSER/$TCDELIVER/remaster && \
    setupHome && \
    chmod 0600 -R /home/$TCUSER/.ssh/* && \
    chmod 0700 /home/$TCUSER/.ssh &&\
    echo etc/init.d/tet-functions >> /opt/.filetool.lst

USER $TCUSER
# These commands require DNS to be setup correctly on the Docker host machine.
# Your '/etc/resolv.conf' file needs to have entries for nameserver that are not localhost
# addresses, and that can resolve external connections, your TCMIRROR at a minimum

WORKDIR /home/$TCUSER

RUN . .ashrc .profile && \
    ( [ ! -z "$TCMIRROR" ] && echo "$TCMIRROR" > /opt/tcemirror||true) && \
    tce-load -wic \
        advcomp.tcz \
        autoconf.tcz \
        automake.tcz \
        bash.tcz \
        compiletc.tcz \
        curl.tcz \
        expat2.tcz \
        gettext.tcz \
        git.tcz \
        intltool.tcz \
        libtool-dev.tcz \
        openssh.tcz \
        perl5.tcz \
        perl_xml_parser.tcz \
        python.tcz \
        squashfs-tools.tcz \
        tar.tcz \
        wget.tcz \
        xz.tcz \
        zsync.tcz \
      && \
    ~/.local/bin/git-clones.sh && \
    ~/.local/bin/update-tet-database && \
    ( tce-load -w python3.5 || true; )
    #sudo chown -R $TCUSER:staff /home/$TCUSER && \

ENTRYPOINT [".local/bin/tc-imager-build.sh"]
#VOLUME /home/$TCUSER/src/tc-diskless-remaster /home/$TCUSER/src/tc-ext-tools /home/$TCUSER/src/tc-ext-tools-packages
