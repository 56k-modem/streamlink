FROM debian:bullseye

ARG USER USER
ARG GROUP GROUP

RUN groupadd -g 1000 $GROUP && useradd -r -u 1000 -g $GROUP $USER && \
    apt-get update && apt-get install -y --no-install-recommends curl ffmpeg python3 python3-pip && \
    pip install --no-cache-dir -U streamlink && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /twitch

WORKDIR /script

COPY streamlinkcmd-docker.sh .

RUN chown -R $USER:$GROUP streamlinkcmd-docker.sh && \
    chmod +x streamlinkcmd-docker.sh

USER $USER

CMD ["./streamlinkcmd-docker.sh"]
