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
# Copy ffmpeg build script.
# See https://github.com/flexconstructor/ffmpeg/build_ffmpeg.sh
COPY          build_ffmpeg.sh /tmp/build_ffmpeg.sh
# Run build script.
RUN           bash /tmp/build_ffmpeg.sh
# Install
RUN           yum -y update mlocate
RUN           yum -y install mlocate
# Copy ibx264 locations to SharedObjects config.
RUN           updatedb && locate libx264.so >> /etc/ld.so.conf
RUN           ldconfig
# Let's make sure the app built correctly
RUN           ffmpeg -buildconf
WORKDIR       /tmp/workdir

CMD           ["--help"]
ENTRYPOINT    ["ffmpeg"]
