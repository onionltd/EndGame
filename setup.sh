#!/bin/bash

#OPTIONS!

MASTERONION="dreadytofatroptsdj6io7l3xptbet6onoyno2yv7jicoxknyazubrad.onion"
TORAUTHPASSWORD="password"

#Shared Front Captcha Key. Key alphanumeric between 64-128. Salt needs to be exactly 8 chars.
KEY="encryption_key"
SALT="salt1234"

#CSS Branding

HEXCOLOR="#9b59b6"

#There is more branding you need to do in the resty/caphtml_d.lua file near the end.

clear

echo "Welcome To The End Game DDOS Prevention Setup..."
sleep 1
BLUE='\033[1;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color
printf "\r\nProvided by your lovely ${BLUE}/u/Paris${NC} from dread. \r\n"
printf "with help from ${BLUE}/u/mr_white${NC} from whitehousemarket.\n"
echo "For the full effects of the DDOS prevention you will need to make sure to setup v3 onionbalance."
echo "Max 6-9 backend instances for each onion. This script will help make the backend instances."

if [ ${#MASTERONION} -lt 62 ]; then
 echo "MASTEWRONION doesn't have the correct length. The url needs to include the .onion at the end." 
 exit 0
fi

if [ -z "$TORAUTHPASSWORD" ]
then
  echo "you didn't enter your tor authpassword"
  exit 0
fi

sleep 5
echo "Proceeding to do the configuration and setup. This will take awhile."


### Configuration
string="s/masterbalanceonion/"
string+="$MASTERONION"
string+="/g"
sed -i $string site.conf

string="s/torauthpassword/"
string+="$torinput"
string+="/g"
sed -i $string site.conf

string="s/encryption_key/"
string+="$KEY"
string+="/g"
sed -i $string lua/cap.lua

string="s/salt1234/"
string+="$SALT"
string+="/g"
sed -i $string lua/cap.lua

string="s/HEXCOLOR/"
string+="$HEXCOLOR"
string+="/g"
sed -i $string cap_d.css

string="s/SITENAME/"
string+="$SITENAME"
string+="/g"
sed -i $string resty/caphtml_d.lua

apt-get update
apt-get install -y apt-transport-https lsb-release ca-certificates dirmngr

echo "deb https://deb.torproject.org/torproject.org buster main" > /etc/apt/sources.list.d/tor.list
echo "deb-src https://deb.torproject.org/torproject.org buster main" >> /etc/apt/sources.list.d/tor.list
echo "deb https://deb.torproject.org/torproject.org tor-nightly-master-buster main" >> /etc/apt/sources.list.d/tor.list
echo "deb-src https://deb.torproject.org/torproject.org tor-nightly-master-buster main" >> /etc/apt/sources.list.d/tor.list
echo "deb https://nginx.org/packages/debian/ buster nginx" > /etc/apt/sources.list.d/nginx.list

gpg --import A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -
apt-key add nginx_signing.key

apt-get update
apt-get install -y tor nyx nginx
apt-get install -y vanguards

command="nginx -v"
nginxv=$( ${command} 2>&1 )
NGINXVERSION=$(echo $nginxv | grep -o '[0-9.]*$')
NGINXOPENSSL="1.1.1d"

wget https://nginx.org/download/nginx-$NGINXVERSION.tar.gz
tar -xzvf nginx-$NGINXVERSION.tar.gz
cd nginx-$NGINXVERSION

apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev uuid-dev gcc git wget curl libgd3 libgd-dev

git clone https://github.com/yorkane/socks-nginx-module.git
git clone https://github.com/nbs-system/naxsi.git
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
--add-dynamic-module=naxsi/naxsi_src \
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

git clone https://github.com/ittner/lua-gd/
cd lua-gd
gcc -o gd.so -DGD_XPM -DGD_JPEG -DGD_FONTCONFIG -DGD_FREETYPE -DGD_PNG -DGD_GIF -O2 -Wall -fPIC -fomit-frame-pointer -I/usr/local/include/luajit-2.1 -DVERSION=\"2.0.33r3\" -shared -lgd luagd.c
mv gd.so /usr/local/lib/lua/5.1/gd.so
cd ..

wget -O /usr/local/lib/lua/resty/aes_functions.lua https://github.com/c64bob/lua-resty-aes/raw/master/lib/resty/aes_functions.lua

#include seems to be a bit mssed up with luajit
mkdir /etc/nginx/resty
ln -s /usr/local/lib/lua/resty/ /etc/nginx/resty/

make -j16 modules

cp -r objs modules
mv modules /etc/nginx/modules
cd ..

mv nginx.conf /etc/nginx/nginx.conf
mv naxsi_core.rules /etc/nginx/naxsi_core.rules
mv naxsi_whitelist.rules /etc/nginx/naxsi_whitelist.rules
mv lua /etc/nginx/
mv resty/* /etc/nginx/resty/resty/
mv /etc/nginx/resty/resty/caphtml_d.lua /etc/nginx/resty/caphtml_d.lua
mkdir /etc/nginx/sites-enabled/
mv site.conf /etc/nginx/sites-enabled/site.conf

#background generation
apt-get install -y  python3-pil 
mv gen_background.py /etc/nginx/gen_background.py
echo "* * * * * root python3 /etc/nginx/gen_background.py" > /etc/cron.d/background-generate
mv font.ttf /etc/nginx/font.ttf
mv cap_d.css /etc/nginx/cap_d.css

chown -R www-data:www-data /etc/nginx/
chown -R www-data:www-data /usr/local/lib/lua

chmod 755 startup.sh
mv startup.sh /startup.sh
chmod 755 rc.local
mv rc.local /etc/rc.local

mv sysctl.conf /etc/sysctl.conf

pkill tor

mv torrc /etc/tor/torrc

torhash=$(tor --hash-password $TORAUTHPASSWORD| tail -c 62)
string="s/hashedpassword/"
string+="$torhash"
string+="/g"
sed -i $string /etc/tor/torrc

sleep 10

tor

sleep 20

HOSTNAME="$(cat /etc/tor/hidden_service/hostname)"

string="s/mainonion/"
string+="$HOSTNAME"
string+="/g"
sed -i $string /etc/nginx/sites-enabled/site.conf

echo "MasterOnionAddress $MASTERONION" >> /etc/tor/hidden_service/ob_config

pkill tor
sleep 10

sed -i "s/#HiddenServiceOnionBalanceInstance/HiddenServiceOnionBalanceInstance/g" /etc/tor/torrc

tor
nginx
service vanguards start

clear

echo "ALL SETUP! Your new front address is"
echo $HOSTNAME
echo "Add it to your onionbalance configuration!"
