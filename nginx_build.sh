DIR=$(mktemp -d) && cd ${DIR}
git clone --depth 1 git://github.com/arut/nginx-rtmp-module.git && \
git clone --depth 1 https://github.com/nginx/nginx.git
ls -la
cd nginx && \
auto/configure \
--add-module=${DIR}/nginx-rtmp-module \
--user=nginx                          \
--group=nginx                         \
--prefix=/etc/nginx                   \
--sbin-path=/usr/sbin/nginx           \
--conf-path=/etc/nginx/nginx.conf     \
--pid-path=/var/run/nginx.pid         \
--lock-path=/var/run/nginx.lock       \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-http_gzip_static_module        \
--with-http_stub_status_module        \
--with-http_ssl_module                \
--with-pcre                           \
--with-file-aio                       \
--with-http_realip_module             \
--without-http_scgi_module            \
--without-http_uwsgi_module           \
--without-http_fastcgi_module && \
make && \
make install && \
make clean && \
rm -rf ${DIR}

