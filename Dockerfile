FROM alpine AS builder

ARG ZSTD_TAG

RUN apk --update upgrade && \
    apk add ca-certificates && \
    apk add --virtual .build-depends \
      curl file git gnupg gzip g++ lz4-dev make jq xz xz-dev zlib-dev && \
    mkdir -v -m 0700 -p /root/.gnupg && \
    gpg2 --no-options --verbose --keyid-format 0xlong --keyserver-options auto-key-retrieve=true \
        --recv-keys 0x4AEE18F83AFDEB23 && \
    git clone --no-checkout --dissociate --reference-if-able /zstd.git \
        'https://github.com/facebook/zstd.git' && \
    [ -n "$ZSTD_TAG" ] || { curl -sSL 'https://api.github.com/repos/facebook/zstd/releases/latest' | jq -r '[.["tag_name"],.["prerelease"]]|select(.[1] == false)|"ZSTD_TAG="+.[0]' > /tmp/latest-tag.sh && . /tmp/latest-tag.sh; } && \
    (cd zstd && { git tag -v "$ZSTD_TAG" || :; } && git checkout "$ZSTD_TAG" && make && make check && make install) && \
    rm -rf /root/.gnupg && \
    sha256sum /usr/local/bin/zstd && /usr/local/bin/zstd -vvV && \
    apk del --purge .build-depends && rm -rf /var/cache/apk/*

FROM alpine
LABEL maintainer="https://keybase.io/tcely"

COPY --from=builder /usr/local /usr/local/

RUN apk --update upgrade && \
    apk add ca-certificates less lz4-libs man xz-libs zlib && \
    rm -rf /var/cache/apk/*

ENV PAGER less
ENTRYPOINT ["/usr/local/bin/zstd"]
CMD ["--help"]
