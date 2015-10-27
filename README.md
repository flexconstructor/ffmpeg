FFMPEG for Docker on Centos7 with Supervisor launcher
============================

This repo has a Dockerfile to create a Docker image wth FFMPEG. It compiles FFMPEG from sources following instructions from the [Centos Compilation Guide](https://trac.ffmpeg.org/wiki/CompilationGuide/Centos).

You can install the latest build of this image by running `docker pull flexconstructor/free-media-server’.

This image can likely be used as a base for a networked encoding farm, based on centos 7.

Test
----

```
$ docker run flexconstructor/free-media-server
ffmpeg version git-2015-10-25-6b5412c Copyright (c) 2000-2015 the FFmpeg developers built with gcc 4.8.3 (GCC) 20140911 (Red Hat 4.8.3-9) 
configuration: --prefix=/usr/local/ffmpeg_build --extra-cflags=-I/usr/local/ffmpeg_build/include --extra-ldflags=-L/usr/local/ffmpeg_build/lib --bindir=/usr/local/bin --pkg-config-flags=--static --enable-gpl --enable-nonfree --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 libavutil 55. 4.100 / 55. 4.100 libavcodec 57. 9.100 / 57. 9.100 libavformat 57. 11.100 / 57. 11.100 libavdevice 57. 0.100 / 57. 0.100 libavfilter 6. 13.100 / 6. 13.100 libswscale 4. 0.100 / 4. 0.100 libswresample 2. 0.100 / 2. 0.100 libpostproc 54. 0.100 / 54. 0.100 Hyper fast Audio and Video encoder
[...]
```

Capture output from the container to the host running the command

```
 docker run flexconstructor/free-media-server \
            -i http://url/to/media.mp4 \
            -stats \
            $ffmpeg_options    -   > out.mp4
```

### Example

```
 docker run flexconstructor/free-media-server -stats  \
        -i http://archive.org/download/thethreeagesbusterkeaton/Buster.Keaton.The.Three.Ages.ogv \
        -loop 0  \
        -final_delay 500 -c:v gif -f gif -ss 00:49:42 -t 5 - > trow_ball.gif
```

See what's inside the beast
---------------------------

```
$ docker run -ti --entrypoint='bash'  flexconstructor/free-media-server
bash-4.1#
```
