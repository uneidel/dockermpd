FROM alpine:3.3
MAINTAINER @uneidel

ENV MPD_VERSION 0.19.12-r0
ENV MPC_VERSION 0.27-r0
ENV SIMA_VERSION 0.14.1
ENV PYTHON_VERSION 3.5.1-r0

# https://docs.docker.com/engine/reference/builder/#arg
ARG user=mpd
ARG group=audio

RUN apk -q update \
    && apk -q --no-progress add mpd="$MPD_VERSION" \
    && apk -q --no-progress add mpc="$MPC_VERSION" \
    && apk -q --no-progress add python3="$PYTHON_VERSION" \
    && apk -q --no-progress add curl \
    && apk -q --no-progress add bash \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /var/lib/mpd/music \
    && mkdir -p /var/lib/mpd/playlists \
    && mkdir -p /var/lib/mpd/database \
    && mkdir -p /var/log/mpd/mpd.log \
    && chown -R ${user}:${group} /var/lib/mpd \
    && chown -R ${user}:${group} /var/log/mpd/mpd.log

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.17.1.2/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz
RUN tar xvfz /tmp/s6-overlay.tar.gz -C /

RUN curl -fsSl http://media.kaliko.me/src/sima/releases/MPD_sima-$SIMA_VERSION.tar.xz -o sima.tar.xz \
    && tar -xJf sima.tar.xz \
    && sed -i 's,https://raw.github.com/pypa/pip/master/contrib/get-pip.py,https://bootstrap.pypa.io/get-pip.py,g' MPD_sima-$SIMA_VERSION/vinstall.py \
    && rm -rf sima.tar.xz \
    && python3 MPD_sima-$SIMA_VERSION/vinstall.py \
    && apk -q --no-progress del curl \
    && rm -rf /var/cache/apk/*

# Declare a music , playlists and database volume (state, tag_cache and sticker.sql)
VOLUME ["/var/lib/mpd/music", "/var/lib/mpd/playlists", "/var/lib/mpd/database"]
COPY mpd.conf /etc/mpd.conf

COPY sima.conf /MPD_sima-$SIMA_VERSION/sima.conf
WORKDIR MPD_sima-$SIMA_VERSION

# Entry point for mpc update and stuff
EXPOSE 6600

ADD root /

ENTRYPOINT ["/init"]
