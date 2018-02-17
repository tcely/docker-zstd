FROM alpine
LABEL maintainer="https://keybase.io/tcely"

RUN apk --update upgrade && \
    apk add ca-certificates less man zstd && \
    rm -rf /var/cache/apk/*

ENV PAGER less
ENTRYPOINT ["/usr/bin/zstd"]
CMD ["--help"]
