# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE}
#
ARG S6ARCH
ARG S6VERSION=3.0.0.0
#
ENV \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
    S6_VERBOSITY=1 \
    PUID=1000 \
    PGID=1000 \
    S6_USER=alpine
#
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-${S6ARCH}.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
#
COPY root/ /
#
RUN set -xe \
    && apk add --no-cache --purge -uU shadow tar xz \
    && echo "using s6: ${S6VERSION} ${S6ARCH}" \
    && tar -C / -Jxpf /tmp/s6-overlay-${S6ARCH}.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz \
    && apk del --purge xz xz-libs \
    && sed -i -e 's/^root::/root:!:/' /etc/shadow \
    && addgroup -g ${PGID} -S ${S6_USER} \
    && adduser -u ${PUID} -G ${S6_USER} -h /home/${S6_USER} -s /bin/false -D ${S6_USER} \
    && sed -i -e "s/@VERSION@/${S6VERSION}/g" /usershell \
    && rm -rf /var/cache/apk/* /tmp/*
#
ENTRYPOINT ["/init"]
# or
# ENTRYPOINT ["/usershell"]
#
# set CMD on test or in child images
# CMD ["/bin/bash"]
