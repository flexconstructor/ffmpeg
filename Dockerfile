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

# ------- init dependecies -----------

RUN set -euo pipefail
RUN yum install -y autoconf automake g++ gcc gcc-c++ libc6-dev git libtool wget make nasm zlib-devel openssl-devel tar xz mercurial cmake perl which vim mlocate nodejs

# ---- Copy ffmpeg build script. -----
# See https://github.com/flexconstructor/ffmpeg/build_ffmpeg.sh
COPY          build_ffmpeg.sh /tmp/build_ffmpeg.sh
# Run build script.
RUN           bash /tmp/build_ffmpeg.sh
# Copy ibx264 locations to SharedObjects config.
RUN           updatedb && locate libx264.so >> /etc/ld.so.conf
RUN           ldconfig
# Let's make sure the app built correctly
RUN           ffmpeg -buildconf

# ---------- install nginx ----------

WORKDIR       ${SRC}
COPY nginx_build.sh /tmp/nginx_build.sh
RUN           bash /tmp/nginx_build.sh
RUN useradd -r nginx
RUN wget -O /etc/init.d/nginx https://gist.github.com/sairam/5892520/raw/b8195a71e944d46271c8a49f2717f70bcd04bf1a/etc-init.d-nginx
RUN chmod +x /etc/init.d/nginx
RUN chkconfig --add nginx
RUN chkconfig --level 345 nginx on

# ------------ install go ---------

WORKDIR  ${SRC}
RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
&& echo "$GOLANG_DOWNLOAD_SHA1  golang.tar.gz" | sha1sum -c - \
&& tar -C /usr/local -xzf golang.tar.gz \
&& rm golang.tar.gz
RUN git clone ${GO_DOCKER_LIB}
RUN cp ${SRC}/golang/go-wrapper /usr/local/bin/
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

#---------- configure nginx -------

RUN mkdir -p /var/sock
RUN chown -R nginx: /var/sock
RUN chmod 755 /var/sock
RUN mkdir -p /var/www/free-media-server.com/public_html
RUN chown -R nginx: /var/www/free-media-server.com/public_html
RUN chmod 755 /var/www/free-media-server.com/public_html
RUN mkdir -p /var/www/free-media-server.com/flvs
RUN chown -R nginx: /var/www/free-media-server.com/flvs
RUN chmod 755 /var/www/free-media-server.com/flvs
RUN wget -O /var/www/free-media-server.com/flvs/big_buck_bunny_720p_2mb.flv http://www.sample-videos.com/video/flv/720/big_buck_bunny_720p_2mb.flv
RUN mkdir -p /var/www/free-media-server.com/mp4
RUN chown -R nginx: /var/www/free-media-server.com/mp4
RUN chmod 755 /var/www/free-media-server.com/mp4
RUN wget -O /var/www/free-media-server.com/mp4/big_buck_bunny_720p_2mb.mp4 http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_2mb.mp4
COPY nginx/free_media_server.conf /etc/nginx/nginx.conf
RUN mkdir /etc/nginx/sites-available
RUN mkdir /etc/nginx/sites-enabled
RUN mkdir /etc/nginx/sites-available/http
RUN mkdir /etc/nginx/sites-available/rtmp
RUN mkdir /etc/nginx/sites-enabled/http
RUN mkdir /etc/nginx/sites-enabled/rtmp
COPY nginx/free_media_server_http.conf /etc/nginx/sites-available/http/free_media_server_http.conf
COPY nginx/free_media_server_rtmp.conf /etc/nginx/sites-available/rtmp/free_media_server_rtmp.conf
RUN ln -s /etc/nginx/sites-available/http/free_media_server_http.conf /etc/nginx/sites-enabled/http/free_media_server_http.conf
RUN ln -s /etc/nginx/sites-available/rtmp/free_media_server_rtmp.conf /etc/nginx/sites-enabled/rtmp/free_media_server_rtmp.conf
COPY nginx/index.html /var/www/free-media-server.com/public_html/index.html
RUN mkdir -p /var/www/free-media-server.com/public_html/temp
RUN mkdir -p /var/www/free-media-server.com/public_html/temp/hls
RUN mkdir -p /var/www/free-media-server.com/public_html/temp/dash

# ---------- Video.js-----------------

RUN mkdir -p /var/www/free-media-server.com/public_html/js
WORKDIR /var/www/free-media-server.com/public_html/js
RUN curl -L https://www.npmjs.com/install.sh | sh
RUN npm install --save-dev video.js
RUN mkdir -p /var/www/free-media-server.com/public_html/js/dist
RUN mkdir -p /var/www/free-media-server.com/public_html/js/dist/videojs
RUN cp -avr /var/www/free-media-server.com/public_html/js/node_modules/video.js/dist /var/www/free-media-server.com/public_html/js/dist/videojs

# ------------clean yum -----------

RUN yum history -y undo last && yum clean all && rm -rf /var/lib/yum/*

# -----------RUN ------------------

EXPOSE 80 443 8081 1935
CMD nginx -s reload

