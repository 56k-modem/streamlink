FROM docker:cli

COPY watch-postproc.sh /watch-postproc.sh
RUN chmod +x /watch-postproc.sh

ENTRYPOINT ["/bin/sh", "/watch-postproc.sh"]
