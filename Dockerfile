FROM flexconstructor/docker-centos-golang
MAINTAINER FlexConstructor <flexconstructor@gmail.com>

# ------------- install dependencies -----------------
RUN set -euo pipefail                       \
    && yum update -y                        \
    && yum install -y openssl-devel

# ----------------- install nginx ---------------------
COPY nginx_build.sh /tmp/nginx_build.sh
RUN chmod 775 /tmp/nginx_build.sh                                                                                                       \
    && bash /tmp/nginx_build.sh                                                                                                         \
    && useradd -r nginx                                                                                                                 \
    && wget -O /etc/init.d/nginx https://gist.github.com/sairam/5892520/raw/b8195a71e944d46271c8a49f2717f70bcd04bf1a/etc-init.d-nginx   \
    && chmod +x /etc/init.d/nginx                                                                                                       \
    && chkconfig --add nginx                                                                                                            \
    && chkconfig --level 345 nginx on
COPY nginx-rtmp.conf /etc/nginx/nginx.conf

# ---------- Writes nginx to supervisord.conf ----------
RUN echo  "[program:nginx]" >> /etc/supervisord.conf \
 && echo  "command = nginx" >> /etc/supervisord.conf 
EXPOSE 8080 1935
CMD ["/usr/bin/supervisord","-n", "-c", "/etc/supervisord.conf"]


