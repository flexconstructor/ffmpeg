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
ENV           GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV           GOLANG_DOWNLOAD_SHA1 46eecd290d8803887dec718c691cc243f2175fe0
ENV           GOPATH /go
ENV           PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV           GO_DOCKER_LIB https://github.com/docker-library/golang.git

# ------- init dependecies -----------
RUN set -euo pipefail
RUN yum update -y
RUN yum install -y autoconf automake g++ gcc gcc-c++ libc6-dev git libtool wget make nasm zlib-devel openssl-devel tar xz mercurial cmake perl which

# ---- Copy ffmpeg build script. -----
# See https://github.com/flexconstructor/ffmpeg/build_ffmpeg.sh
COPY          build_ffmpeg.sh /tmp/build_ffmpeg.sh
# Run build script.
RUN           bash /tmp/build_ffmpeg.sh
# Install mlocate
RUN           yum -y update mlocate
RUN           yum -y install mlocate
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

# ------------clean yum -----------
RUN yum history -y undo last && yum clean all && rm -rf /var/lib/yum/*
# -----------RUN ------------------
EXPOSE 80 443
CMD nginx -s reload
