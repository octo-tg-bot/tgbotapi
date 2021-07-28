# syntax = docker/dockerfile:experimental
FROM alpine:latest AS build-env
WORKDIR /src
RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake ccache
ARG CHECKOUT_REF=master
ENV CCACHE_DIR=/ccache
RUN for p in gcc g++ cc c++; do ln -vs /usr/bin/ccache /usr/local/bin/$p;  done
RUN git init && \
    git remote add upstream https://github.com/tdlib/telegram-bot-api.git && \
    git fetch upstream ${CHECKOUT_REF} && \
    git reset --hard FETCH_HEAD && \
    git submodule init && git submodule update
# COPY patches patches
# RUN git apply --ignore-whitespace patches/*.patch
RUN --mount=type=cache,target=/ccache/ ccache -s
RUN --mount=type=cache,target=/ccache/ rm -rf build && mkdir -p build && cd build && \ 
    export CXXFLAGS="" && cmake -DCMAKE_BUILD_TYPE=Release .. -DCMAKE_INSTALL_PREFIX:PATH=.. .. && \
    echo building with $(nproc) cores && cmake --build . -j $(nproc) --target install
RUN --mount=type=cache,target=/ccache/ ccache -s

FROM nginx:1.19-alpine AS exec-env
WORKDIR /app
RUN apk add --no-cache openssl zlib libstdc++
COPY --from=build-env /src/bin/telegram-bot-api .
RUN mkdir /file && chown nginx:nginx /file -R && chmod ugo+rw /file -R
RUN adduser -S botapi -G nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY start_api.sh .
RUN chmod +x start_api.sh
ENTRYPOINT [ "./start_api.sh"]
