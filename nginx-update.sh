#!/bin/bash

apt-get update
apt-get -y upgrade

command="nginx -v"
nginxv=$( ${command} 2>&1 )
NGINXVERSION=$(echo $nginxv | grep -o '[0-9.]*$')

NGINXOPENSSL="1.1.1d"

wget https://nginx.org/download/nginx-$NGINXVERSION.tar.gz
tar -xzvf nginx-$NGINXVERSION.tar.gz

cp -R dependencies/* nginx-$NGINXVERSION/

cd nginx-$NGINXVERSION

wget https://www.openssl.org/source/openssl-$NGINXOPENSSL.tar.gz
tar -xzvf openssl-$NGINXOPENSSL.tar.gz

export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1
./configure --with-cc-opt='-Wno-stringop-overflow -Wno-stringop-truncation -Wno-cast-function-type' \
--with-ld-opt="-Wl,-rpath,/usr/local/lib" \
--with-compat --with-openssl=openssl-$NGINXOPENSSL \
--with-http_ssl_module \
--add-dynamic-module=naxsi/naxsi_src \
--add-dynamic-module=headers-more-nginx-module \
--add-dynamic-module=socks-nginx-module \
--add-dynamic-module=echo-nginx-module \
 --add-dynamic-module=ngx_devel_kit \
--add-dynamic-module=lua-nginx-module 

make -j16 modules

cp -r objs modules
rm -R /etc/nginx/modules
mkdir /etc/nginx/modules
mv modules /etc/nginx/modules