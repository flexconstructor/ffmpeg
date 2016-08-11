# ffmpeg
# From https://trac.ffmpeg.org/wiki/CompilationGuide/Centos
#
FROM          modelboard/centos-supervisord
MAINTAINER    Julien Rottenberg <julien@rottenberg.info>
ENV           YASM_VERSION    1.3.0
ENV           OGG_VERSION     1.3.2
ENV           VORBIS_VERSION  1.3.4
ENV           LAME_VERSION    3.99.5
ENV           SRC             /usr/local
ENV           PKG_CONFIG_PATH ${SRC}/lib/pkgconfig
ENV           GOLANG_VERSION 1.5.1
ENV           GOLANG_DOWNLOAD_URL https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
ENV           GOLANG_DOWNLOAD_SHA1 46eecd290d8803887dec718c691cc243f2175fe0
ENV           GOPATH /go
ENV           GOBIN ${GOPATH}/bin/
ENV           PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV           GO_DOCKER_LIB https://github.com/docker-library/golang.git

#-------- Copy files -----------------

COPY nginx_build.sh /tmp/nginx_build.sh
COPY build_ffmpeg.sh /tmp/build_ffmpeg.sh

# ------- init dependecies -----------

RUN set -euo pipefail                       \                   \
    && yum install -y autoconf automake g++ \
                      gcc gcc-c++           \
                      libc6-dev git         \
                      libtool               \
                      wget                  \
                      make                  \
                      nasm                  \
                      zlib-devel            \
                      openssl-devel         \
                      tar                   \
                      xz                    \
                      mercurial             \
                      cmake                 \
                      perl                  \
                      which                 \
                      mlocate               \
                      nodejs

# ---- Copy ffmpeg build script. -----
# See https://github.com/flexconstructor/ffmpeg/build_ffmpeg.sh

# Run build script.
RUN bash /tmp/build_ffmpeg.sh                           \
# Copy ibx264 locations to SharedObjects config.
    && updatedb && locate libx264.so >> /etc/ld.so.conf \
    && ldconfig                                         \
# Let's make sure the app built correctly
    && ffmpeg -buildconf


# ------------ install go ---------

WORKDIR  ${SRC}
RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz                 \
    && echo "$GOLANG_DOWNLOAD_SHA1  golang.tar.gz" | sha1sum -c -      \
    && tar -C /usr/local -xzf golang.tar.gz                            \
    && rm golang.tar.gz                                                \
    && git clone ${GO_DOCKER_LIB}                                      \
    && cp ${SRC}/golang/go-wrapper /usr/local/bin/                     \
    && mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# ---------- install nginx ----------


RUN bash /tmp/nginx_build.sh                                                                                                                            \
    && useradd -r nginx                                                                                                                                 \
    && wget -O /etc/init.d/nginx https://gist.github.com/sairam/5892520/raw/b8195a71e944d46271c8a49f2717f70bcd04bf1a/etc-init.d-nginx                   \
    && chmod +x /etc/init.d/nginx                                                                                                                       \
    && chkconfig --add nginx                                                                                                                            \
    && chkconfig --level 345 nginx on                                                                                                                   \


#---------- configure nginx -------

    && mkdir -p /var/sock                                                                                                                               \
    && chown -R nginx: /var/sock                                                                                                                        \
    && chmod 755 /var/sock                                                                                                                              \
    && mkdir -p /var/www/free-media-server.com/public_html                                                                                              \
    && chown -R nginx: /var/www/free-media-server.com/public_html                                                                                       \
    && chmod 755 /var/www/free-media-server.com/public_html                                                                                             \
    && mkdir -p /var/www/free-media-server.com/flvs                                                                                                     \
    && chown -R nginx: /var/www/free-media-server.com/flvs                                                                                              \
    && chmod 755 /var/www/free-media-server.com/flvs                                                                                                    \
    && wget -O /var/www/free-media-server.com/flvs/big_buck_bunny_720p_2mb.flv http://www.sample-videos.com/video/flv/720/big_buck_bunny_720p_2mb.flv   \
    && mkdir -p /var/www/free-media-server.com/mp4                                                                                                      \
    && chown -R nginx: /var/www/free-media-server.com/mp4                                                                                               \
    && chmod 755 /var/www/free-media-server.com/mp4                                                                                                     \
    && wget -O /var/www/free-media-server.com/mp4/big_buck_bunny_720p_2mb.mp4 http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_2mb.mp4    \
    && mkdir /etc/nginx/sites-available                                                                                                                 \
    && mkdir /etc/nginx/sites-enabled                                                                                                                   \
    && mkdir /etc/nginx/sites-available/http                                                                                                            \
    && mkdir /etc/nginx/sites-available/rtmp                                                                                                            \
    && mkdir /etc/nginx/sites-enabled/http                                                                                                              \
    && mkdir /etc/nginx/sites-enabled/rtmp                                                                                                              \
    && mkdir -p /var/www/free-media-server.com/public_html/temp                                                                                         \
    && mkdir -p /var/www/free-media-server.com/public_html/temp/hls                                                                                     \
    && mkdir -p /var/www/free-media-server.com/public_html/temp/dash

COPY nginx/free_media_server_http.conf /etc/nginx/sites-available/http/free_media_server_http.conf
COPY nginx/free_media_server_rtmp.conf /etc/nginx/sites-available/rtmp/free_media_server_rtmp.conf
RUN ln -s /etc/nginx/sites-available/http/free_media_server_http.conf /etc/nginx/sites-enabled/http/free_media_server_http.conf     \
    && ln -s /etc/nginx/sites-available/rtmp/free_media_server_rtmp.conf /etc/nginx/sites-enabled/rtmp/free_media_server_rtmp.conf
COPY nginx/index.html /var/www/free-media-server.com/public_html/index.html
COPY nginx/free_media_server.conf /etc/nginx/nginx.conf

# ---------- Video.js-----------------

RUN mkdir -p /var/www/free-media-server.com/public_html/js
WORKDIR /var/www/free-media-server.com/public_html/js
RUN curl -L https://www.npmjs.com/install.sh | sh                                                                                                   \
    && npm install --save-dev video.js                                                                                                              \
    && mkdir -p /var/www/free-media-server.com/public_html/js/dist                                                                                  \
    && mkdir -p /var/www/free-media-server.com/public_html/js/dist/videojs                                                                          \
    && cp -avr /var/www/free-media-server.com/public_html/js/node_modules/video.js/dist /var/www/free-media-server.com/public_html/js/dist/videojs

# ------------clean yum -----------

RUN yum history -y undo last && yum clean all && rm -rf /var/lib/yum/*

# -----------RUN ------------------

EXPOSE 80 443 8081 1935
CMD nginx -s reload

