FROM debian:bullseye

RUN groupadd -g 1000 $USER && useradd -r -u 1000 -g $USER $USER && \
    apt-get update && apt-get install -y curl ffmpeg python3 python3-pip && \
    pip install --no-cache-dir -U streamlink && \
    mkdir /twitch

WORKDIR /script

COPY streamlinkcmd-docker.sh .

RUN chown -R $USER:$USER streamlinkcmd-docker.sh && \
    chmod +x streamlinkcmd-docker.sh

USER $USER

CMD ["./streamlinkcmd-docker.sh"]