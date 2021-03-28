#!/bin/bash

apt-get update
apt-get -y upgrade

command="nginx -v"
nginxv=$( ${command} 2>&1 )
NGINXVERSION=$(echo $nginxv | grep -o '[0-9.]*$')
NGINXOPENSSL="1.1.1d"

wget https://nginx.org/download/nginx-$NGINXVERSION.tar.gz
tar -xzvf nginx-$NGINXVERSION.tar.gz
cd nginx-$NGINXVERSION

apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev gcc git wget curl libgd3 libgd-dev

wget https://github.com/apache/incubator-pagespeed-ngx/archive/latest-beta.tar.gz
tar -xzvf latest-beta.tar.gz
cd incubator-pagespeed-ngx-latest-beta
wget https://dl.google.com/dl/page-speed/psol/1.13.35.2-x64.tar.gz
tar -xzvf 1.13.35.2-x64.tar.gz 
cd ..

git clone https://github.com/yorkane/socks-nginx-module
git clone https://github.com/nbs-system/naxsi.git
git clone https://github.com/kyprizel/testcookie-nginx-module.git
wget https://www.openssl.org/source/openssl-$NGINXOPENSSL.tar.gz
tar -xzvf openssl-$NGINXOPENSSL.tar.gz
git clone https://github.com/openresty/headers-more-nginx-module.git
git clone https://github.com/openresty/echo-nginx-module.git

#some required stuff for lua/luajit. obviously versions should be ckecked with every install/update
git clone https://github.com/openresty/lua-nginx-module
cd lua-nginx-module
git checkout v0.10.16
cd ..
git clone https://github.com/openresty/luajit2
cd luajit2
git checkout v2.1-20200102
cd ..
git clone https://github.com/vision5/ngx_devel_kit
cd luajit2
make -j8 && make install
cd ..

export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1
./configure --with-cc-opt='-Wno-stringop-overflow -Wno-stringop-truncation -Wno-cast-function-type' \
--with-ld-opt="-Wl,-rpath,/usr/local/lib" \
--with-compat --with-openssl=openssl-$NGINXOPENSSL \
--with-http_ssl_module \
--add-dynamic-module=incubator-pagespeed-ngx-latest-beta \
--add-dynamic-module=naxsi/naxsi_src --add-dynamic-module=testcookie-nginx-module \
--add-dynamic-module=headers-more-nginx-module \
--add-dynamic-module=socks-nginx-module \
--add-dynamic-module=echo-nginx-module \
 --add-dynamic-module=ngx_devel_kit \
--add-dynamic-module=lua-nginx-module 

git clone https://github.com/openresty/lua-resty-string
cd lua-resty-string
make install
cd ..

git clone https://github.com/cloudflare/lua-resty-cookie
cd lua-resty-cookie
make install
cd ..

git clone https://github.com/bungle/lua-resty-session
cp -a lua-resty-session/lib/resty/session* /usr/local/lib/lua/resty/

wget -O /usr/local/lib/lua/resty/aes_functions.lua https://github.com/c64bob/lua-resty-aes/raw/master/lib/resty/aes_functions.lua

#include seems to be a bit mssed up with luajit
mkdir /etc/nginx/resty
ln -s /usr/local/lib/lua/resty/ /etc/nginx/resty/

wget -O /usr/local/lib/lua/resty/random.lua https://raw.githubusercontent.com/bungle/lua-resty-random/master/lib/resty/random.lua

make -j16 modules

cp -r objs modules
rm -R /etc/nginx/modules/modules
mv modules /etc/nginx/modules