##!/bin/bash

# ------- Yasm ------------
# Yasm is an assembler used by x264 and FFmpeg.
DIR=$(mktemp -d) && cd ${DIR} && \
git clone --depth 1 git://github.com/yasm/yasm.git && \
cd yasm && \
autoreconf -fiv && \
./configure --prefix="$(SRC)/ffmpeg_build" --bindir="${SRC}/bin" && \
make && \
make install && \
make distclean && \
rm -rf ${DIR}

# ------- x264 -------------
# H.264 video encoder.
DIR=$(mktemp -d) && cd ${DIR} && \
git clone --depth 1 git://git.videolan.org/x264 && \
cd x264 && \
./configure --prefix="${SRC}/ffmpeg_build" --bindir="${SRC}/bin" --enable-static --enable-shared  && \
make && \
make install && \
make distclean && \
rm -rf ${DIR}

# --------- x265 ----------
# H.265/HEVC video encoder.
DIR=$(mktemp -d) && cd ${DIR} && \
hg clone https://bitbucket.org/multicoreware/x265 && \
cd x265/build/linux && \
PATH="${SRC}/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${SRC}/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source && \
make && \
make install && \
rm -rf ${DIR}

# --------- fdk-aac ----------
# AAC audio encoder.
DIR=$(mktemp -d) && cd ${DIR} && \
git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac && \
cd fdk-aac && \
autoreconf -fiv && \
./configure --prefix="${SRC}/ffmpeg_build" --disable-shared && \
make && \
make install && \
make distclean && \
rm -rf ${DIR}

#----------libmp3lame ----------
# MP3 audio encoder.
DIR=$(mktemp -d) && cd ${DIR} && \
curl -L -O http://downloads.sourceforge.net/project/lame/lame/${LAME_VERSION%.*}/lame-${LAME_VERSION}.tar.gz && \
tar xzvf lame-${LAME_VERSION}.tar.gz && \
cd lame-${LAME_VERSION} && \
./configure --prefix="${SRC}/ffmpeg_build" --bindir="${SRC}/bin" --disable-shared --enable-nasm && \
make && \
make install && \
make distclean && \
rm -rf ${DIR}

# ------------ libopus ----------
# Opus audio decoder and encoder.
DIR=$(mktemp -d) && cd ${DIR} && \
git clone git://git.opus-codec.org/opus.git && \
cd opus && \
autoreconf -fiv && \
./configure --prefix="${SRC}/ffmpeg_build" --disable-shared && \
make && \
make install && \
make distclean && \
rm -rf ${DIR}

# ------------- libogg -----------
# Ogg bitstream library. Required by libtheora and libvorbis.
DIR=$(mktemp -d) && cd ${DIR} && \
curl -O http://downloads.xiph.org/releases/ogg/libogg-${OGG_VERSION}.tar.gz && \
tar xzvf libogg-${OGG_VERSION}.tar.gz && \
cd libogg-${OGG_VERSION} && \
./configure --prefix="${SRC}/ffmpeg_build" --disable-shared
make && \
make install && \
make distclean && \
rm -rf ${DIR}

#------------- libvorbis -----------
# Vorbis audio encoder. Requires libogg.
DIR=$(mktemp -d) && cd ${DIR} && \
curl -O http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz && \
tar xzvf libvorbis-${VORBIS_VERSION}.tar.gz && \
cd libvorbis-${VORBIS_VERSION} && \
LDFLAGS="-L${SRC}/ffmeg_build/lib" CPPFLAGS="-I${SRC}/ffmpeg_build/include" ./configure --prefix="${SRC}/ffmpeg_build" --with-ogg="${SRC}/ffmpeg_build" --disable-shared && \
make && \
make install && \
make distclean && \
rm -rf ${DIR}

# -------------- libvpx --------------
# VP8/VP9 video encoder.
DIR=$(mktemp -d) && cd ${DIR} && \
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
cd libvpx && \
./configure --prefix="${SRC}/ffmpeg_build" --disable-examples && \
make && \
make install && \
make clean && \
rm -rf ${DIR}

# -------------- Freetype ------------
# FreeType is a freely available software library to render fonts
yum install -y freetype.x86_64 && yum install -y freetype-devel.x86_64
# Export PKG_CONFIG_PATH
export PKG_CONFIG_PATH="${SRC}/ffmpeg_build/lib/pkgconfig"

# ---------------- FFMPEG -------------
# Configure and install FFMPEG
DIR=$(mktemp -d) && cd ${DIR} && \
git clone --depth 1 git://source.ffmpeg.org/ffmpeg && \
cd ffmpeg && \
PKG_CONFIG_PATH="${SRC}/ffmpeg_build/lib/pkgconfig" && \
./configure --prefix="${SRC}/ffmpeg_build" --extra-cflags="-I${SRC}/ffmpeg_build/include" --extra-ldflags="-L${SRC}/ffmpeg_build/lib" --bindir="${SRC}/bin" --pkg-config-flags="--static" --enable-gpl --enable-nonfree --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265
make && \
make install && \
make distclean && \
hash -r && \
cd tools
make qt-faststart
cp qt-faststart ${SRC}/bin
rm -rf ${DIR}
# register Shared Objects
echo "${SRC}/ffmpeg_build/lib" >> /etc/ld.so.conf.d/libc.conf


