#!/bin/bash

#OPTIONS!

MASTERONION="dreadytofatroptsdj6io7l3xptbet6onoyno2yv7jicoxknyazubrad.onion"
TORAUTHPASSWORD="changethispassowrd"
BACKENDONIONURL="biblemeowimkh3utujmhm6oh2oeb3ubjw2lpgeq3lahrfr2l6ev6zgyd.onion"

#set to true if you want to setup local proxy instead of proxy over Tor
LOCALPROXY=false
PROXYPASSURL="10.10.10.10:80"

#Shared Front Captcha Key. Key alphanumeric between 64-128. Salt needs to be exactly 8 chars.
KEY="encryption_key"
SALT="1saltkey"
SESSION_LENGTH=3600

#CSS Branding

HEXCOLOR="9b59b6"
HEXCOLORDARK="6d3d82"
SITENAME="dread"

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
echo "Onionbalance v3 does have distinct descriptors in a forked version. Read the README.MD in the onionbalance folder for more information."

if [ ${#MASTERONION} -lt 62 ]; then
 echo "MASTEWRONION doesn't have the correct length. The url needs to include the .onion at the end." 
 exit 0
fi

if [ -z "$TORAUTHPASSWORD" ]
then
  echo "you didn't enter your tor authpassword"
  exit 0
fi

shopt -s nullglob dotglob
directory=(dependencies/*)
if [ ${#directory[@]} -gt 0 ]
then
echo "Dependency Folder Found!"
else
echo "You need to get the dependencies first. Run './getdependencies.sh'"
exit 0
fi

echo "Proceeding to do the configuration and setup. This will take awhile."
sleep 5

### Configuration
string="s/masterbalanceonion/"
string+="$MASTERONION"
string+="/g"
sed -i $string site.conf

string="s/torauthpassword/"
string+="$TORAUTHPASSWORD"
string+="/g"
sed -i $string site.conf

string="s/backendurl/"
string+="$BACKENDONIONURL"
string+="/g"
sed -i $string site.conf

string="s/proxypassurl/"
string+="$PROXYPASSURL"
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

string="s/sessionconfigvalue/"
string+="$SESSION_LENGTH"
string+="/g"
sed -i $string lua/cap.lua

string="s/HEXCOLOR/"
string+="$HEXCOLOR"
string+="/g"
sed -i $string cap_d.css

string="s/HEXCOLOR/"
string+="$HEXCOLOR"
string+="/g"
sed -i $string queue.html

string="s/HEXCOLORDARK/"
string+="$HEXCOLORDARK"
string+="/g"
sed -i $string queue.html

string="s/SITENAME/"
string+="$SITENAME"
string+="/g"
sed -i $string queue.html

string="s/SITENAME/"
string+="$SITENAME"
string+="/g"
sed -i $string resty/caphtml_d.lua

if $LOCALPROXY
then
string="s/#proxy_pass/"
string+="proxy_pass"
string+="/g"
sed -i $string site.conf
else
string="s/#socks_/"
string+="socks_"
string+="/g"
sed -i $string site.conf
fi

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
apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev uuid-dev gcc git wget curl libgd3 libgd-dev

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

cd luajit2
make -j8 && make install
cd ..

cd lua-resty-string
make install
cd ..

cd lua-resty-cookie
make install
cd ..

cd lua-gd
gcc -o gd.so -DGD_XPM -DGD_JPEG -DGD_FONTCONFIG -DGD_FREETYPE -DGD_PNG -DGD_GIF -O2 -Wall -fPIC -fomit-frame-pointer -I/usr/local/include/luajit-2.1 -DVERSION=\"2.0.33r3\" -shared -lgd luagd.c
mv gd.so /usr/local/lib/lua/5.1/gd.so
cd ..

cp -a lua-resty-session/lib/resty/session* /usr/local/lib/lua/resty/

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

#https://github.com/c64bob/lua-resty-aes/raw/master/lib/resty/aes_functions.lua
mv resty/aes_functions.lua /usr/local/lib/lua/resty/aes_functions.lua 

mkdir /etc/nginx/resty/
#include seems to be a bit mssed up with luajit
ln -s /usr/local/lib/lua/resty/ /etc/nginx/resty/

make -j16 modules

cp -r objs modules
rm -R /etc/nginx/modules
mkdir /etc/nginx/modules
mv modules /etc/nginx/modules
cd ..

rm /etc/nginx/nginx.conf
mv nginx.conf /etc/nginx/nginx.conf
rm /etc/nginx/naxsi_core.rules
mv naxsi_core.rules /etc/nginx/naxsi_core.rules
rm /etc/nginx/naxsi_whitelist.rules
mv naxsi_whitelist.rules /etc/nginx/naxsi_whitelist.rules
rm -R /etc/nginx/lua/
mv lua /etc/nginx/
mv resty/* /etc/nginx/resty/resty/
rm /etc/nginx/resty/caphtml_d.lua
mv /etc/nginx/resty/resty/caphtml_d.lua /etc/nginx/resty/caphtml_d.lua
rm /etc/nginx/resty/resty/random.lua
mv random.lua /etc/nginx/resty/resty/random.lua
mv queue.html /etc/nginx/queue.html
rm -R /etc/nginx/sites-enabled/
mkdir /etc/nginx/sites-enabled/
mv site.conf /etc/nginx/sites-enabled/site.conf
rm /etc/nginx/cap_d.css
mv cap_d.css /etc/nginx/cap_d.css

chown -R www-data:www-data /etc/nginx/
chown -R www-data:www-data /usr/local/lib/lua

chmod 755 startup.sh
rm /startup.sh
mv startup.sh /startup.sh
chmod 755 rc.local
rm /etc/rc.local
mv rc.local /etc/rc.local

rm /etc/sysctl.conf
mv sysctl.conf /etc/sysctl.conf

pkill tor

mv torrc /etc/tor/torrc

if $LOCALPROXY
then
echo "localproxy enabled"
else
mv torrc2 /etc/tor/torrc2
mv torrc3 /etc/tor/torrc3
fi

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

echo "MasterOnionAddress $MASTERONION" > /etc/tor/hidden_service/ob_config

pkill tor
sleep 10

sed -i "s/#HiddenServiceOnionBalanceInstance/HiddenServiceOnionBalanceInstance/g" /etc/tor/torrc

tor

if $LOCALPROXY
then
echo "localproxy enabled"
else
tor -f /etc/tor/torrc2
tor -f /etc/tor/torrc3
fi

nginx
service vanguards start
nginx -s stop
nginx

clear

echo "ALL SETUP! Your new front address is"
echo $HOSTNAME
echo "Add it to your onionbalance configuration!"
