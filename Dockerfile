FROM tatsushid/tinycore:7.2-x86_64
# Instructions are run with 'tc' user

# <local TC mirror> = http://pecan.digium.internal:81/tinycore-testing/
# docker build --build-arg TCMIRROR=<local TC mirror> -t chazzam/tetr:7.2-x86_64 -t chazzam/tetr:latest-x86_64 .
# docker run -e TCMIRROR=<local TC mirror> -v $HOME/tc-deliver:/home/tc/tc-deliver:rw chazzam/tetr:7.2-x86_64
ARG TCMIRROR
ARG TETR_SCRIPTS_REPO=https://github.com/chazzam/tetr-scripts.git

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV TCUSER="tc" LANG=C.UTF-8 LC_ALL=C LANGUAGE=C.UTF-8 \
    TCDELIVER="tc-deliver"

# These commands require DNS to be setup correctly on the Docker host machine.
# Your '/etc/resolv.conf' file needs to have entries for nameserver that are not localhost
# addresses, and that can resolve external connections, your TCMIRROR at a minimum

WORKDIR /home/$TCUSER

RUN true && \
    . .ashrc .profile && \
    mkdir -p /home/$TCUSER/$TCDELIVER/packages /home/$TCUSER/$TCDELIVER/remaster && \
    ( [ ! -z "$TCMIRROR" ] && echo "$TCMIRROR" > /opt/tcemirror||true) && \
    tce-load -wic \
        expat2.tcz \
        git.tcz \
      && \
    git clone ${TETR_SCRIPTS_REPO} tetr-scripts && \
    ( cd tetr-scripts/include && \
    ./install.sh )

ENTRYPOINT [".local/bin/tc-imager-build.sh"]
