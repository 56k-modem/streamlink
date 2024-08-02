FROM alpine:3.20.1
RUN addgroup -g 1000 csd && adduser -S -u 1000 -G csd csd && \
    apk update && apk add --no-cache curl ffmpeg python3 py3-pip bash tzdata && \
    cp /usr/share/zoneinfo/Europe/Budapest /etc/localtime && \
    echo "Europe/Budapest" > /etc/timezone && \
    pip install --break-system-packages streamlink && \
    mkdir /twitch
ENV TZ=Europe/Budapest
WORKDIR /script
COPY streamlinkcmd-docker.sh oauth.txt ./
RUN chown csd:csd streamlinkcmd-docker.sh oauth.txt && \
    chmod +x streamlinkcmd-docker.sh
USER csd
CMD ["/bin/bash","./streamlinkcmd-docker.sh"]
