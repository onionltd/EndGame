#/bin/bash

clear
echo "Welcome To The End Game DDOS OnionBalance Setup."
sleep 0.5
echo "Starting now!"

apt-get update
apt-get install -y apt-transport-https lsb-release ca-certificates dirmngr git python3-setuptools python3-dev gcc libyaml-0-2

echo "deb https://deb.torproject.org/torproject.org buster main" >> /etc/apt/sources.list.d/tor.list
echo "deb-src https://deb.torproject.org/torproject.org buster main" >> /etc/apt/sources.list.d/tor.list
echo "deb https://deb.torproject.org/torproject.org tor-nightly-master-buster main" >> /etc/apt/sources.list.d/tor.list
echo "deb-src https://deb.torproject.org/torproject.org tor-nightly-master-buster main" >> /etc/apt/sources.list.d/tor.list

wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

apt-get update
apt-get install -y tor nyx
apt-get install -y vanguards

service tor stop
rm /etc/tor/torrc
mv torrc /etc/tor/torrc

git clone https://github.com/zscole/onionbalance.git
cd onionbalance
python3 setup.py install

clear
onionbalance-config --hs-version v3 -n 3

echo "Setup Done.You need to do configuration"
