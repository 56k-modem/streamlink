FROM python:3.12.7-slim-bookworm
ENV streamlinkCommit=d3828a5e7b7025856d800c231b222ea64004dc37
RUN groupadd -g 1000 csd && useradd -m -u 1000 -g csd csd && \
    apt-get update && apt-get install -y --no-install-recommends ffmpeg procps curl git python3-pip xz-utils \
    && TARBALL="ffmpeg-git-amd64-static.tar.xz" \
    && TMP_DIR=$(mktemp -d) \
    && curl -sS -o "${TMP_DIR}/${TARBALL}" "https://johnvansickle.com/ffmpeg/builds/${TARBALL}" \
    && curl -sS -o "${TMP_DIR}/${TARBALL}.md5" "https://johnvansickle.com/ffmpeg/builds/${TARBALL}.md5" \
    && (cd "$TMP_DIR" && md5sum -c "${TARBALL}.md5") \
    && tar -xf "${TMP_DIR}/${TARBALL}" -C "$TMP_DIR" \
    && EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name 'ffmpeg-*-static' | head -1) \
    && install -m 755 "${EXTRACTED_DIR}/ffmpeg" /usr/local/bin/ffmpeg \
    && install -m 755 "${EXTRACTED_DIR}/ffprobe" /usr/local/bin/ffprobe \
    && rm -rf "$TMP_DIR" && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --root-user-action=ignore --upgrade pip && \
    pip install --root-user-action=ignore --upgrade git+https://github.com/streamlink/streamlink.git@${streamlinkCommit} && \
    mkdir /wubby && mkdir /test
ENV TZ=Europe/Budapest
WORKDIR /script
COPY streamlinkcmd-twitch.sh streamlinkcmd-kick.sh streamlinkcmd-test.sh ./
RUN chown csd:csd streamlinkcmd-twitch.sh streamlinkcmd-kick.sh streamlinkcmd-test.sh && \
    chmod +x streamlinkcmd-twitch.sh streamlinkcmd-kick.sh streamlinkcmd-test.sh
USER csd
