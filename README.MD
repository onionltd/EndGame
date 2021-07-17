# EndGame V2 - Onion Service DDOS Prevention Front System

V2 Provided by [Dread](http://dreadytofatroptsdj6io7l3xptbet6onoyno2yv7jicoxknyazubrad.onion/) and [White House Market](http://dreadytofatroptsdj6io7l3xptbet6onoyno2yv7jicoxknyazubrad.onion/d/WhiteHouseMarket).

**Should be used with this [onionbalance](https://github.com/zscole/onionbalance) process for distinct descriptors. Use one onion for everything.**

EndGame is

- a front system designed to protect the core application servers on an onion service in a safe and private way.
- locally complied and locally run (no trusted or middle party).
- a combination of multiple different technologies working together in harmony (listed below).
- FREE FOR ALL TO USE!
- *arguably* magic ㄟ( ▔, ▔ )ㄏ

# Main Features

- Fully scripted and easily deploy-able (for mass scaling!) on blank Debian 10 systems.
- Full featured NGINX LUA script to filter packets and provide a captcha directly using the NGINX layer.
- Rate limiting via Tor's V3 onion service circuit ID system with secondary rate limiting based on a testcookie like system.
- Easy Configuration for both local and remote (over Tor) front systems.
- Easily configurable and change-able to meet an onion service's needs.

It can also:
- Cause you to grow a bigger dick than the asshole DDOSER (true *figurally*, lies *probably*)
- Save you millions of dollars do to DDOSER's downing your site for ransom or for their extorting fees.
- Make it look like you know what the fuck you are doing.

# V2 Updates
V2 EndGame has updates to the broken captcha generation process using a clock facing captcha. It includes extra features like
- updated documentation
- load balanced Tor socks processes for more stable socks_passes
- unix listening instead of ports for performance, stability, and security
- true randomization for captcha and cookie generation
- simple queue system (time based, read below)
- various theme configuration options right on the setup file
- dependency script to get all the dependencies only once. Effectively snapshotting all dependencies preventing future dependency repo exploits in the VERY unlikely case a repo was to get compromised. Paranoia mode.
- bug fixes and various performance tunings

### Notes About Queue System

V2 introduces a queue system which effectively prevents CPU exhaustion from mass get attacks. The clock captcha generation is computationally intensive and specifically vulnerable to this kind of attack. By limiting the amount of connections and amount of captcha tries it greatly reduces the CPU cycles to handle the attack.

In this version there is a simple time on line 110 of the `lua/cap.lua` file which gets checked on line 143. It is recommended to variate this value by attaching a sliding scale time circumstance base on front CPU load. Exponential functions based on the "/proc/stat" value. If you do that, keep the curve private because there is always an "ideal" attack value.
When you set set the time value update the `queue.html` file via a script to rewrite the meta refresh variable.

### Tech Overview

Endgame uses a number of open source projects (and libraries) to work properly.

Projects:
* [NGINX](https://NGINX.org/) - NGINX! A web server *obviously* to provide the packet handling, threading, and proxying.
* [Tor](https://www.torproject.org/) - Tor is free and open-source software for enabling anonymous communication. It's awesome and makes all this possible.
* [Vanguards](https://github.com/mikeperry-tor/vanguards) - A safer onion service circuit building system (to prevent some traffic analysis attacks)
* [STEM](https://stem.torproject.org/) - A python controller for Tor.
* [NYX](https://nyx.torproject.org/) - A command-line monitor for Tor (to easily check the endgame front's Tor process.
* [V3 OnionBalance](https://github.com/asn-d6/onionbalance) - A distributed DNS round-robin like system on Tor to allow load-balancing and elimiate single points of failure.
* [OpenSSL](https://www.openssl.org/) - A dependency for a lot of this projects and libraries.
* [Python3](https://www.python.org/) - A easy to work with programming language we use for background image generation.

NGINX Modules:
* [Socks NGINX](https://github.com/yorkane/socks-NGINX-module) - A NGINX module to allow proxying to Tor onion services directly on the NGINX layer.
* [NAXSI](https://github.com/nbs-system/naxsi) - A high performance web application firewall for NGINX.
* [Headers More](https://github.com/openresty/headers-more-NGINX-module) - A module for better control of headers in NGINX.
* [Echo NGINX](https://github.com/openresty/echo-nginx-module) - A NGINX module which allows shell style commands in the NGINX configuration file.
* [LUA NGINX](https://github.com/openresty/lua-nginx-module) - The power of LUA into NGINX via a module. This allows all the scripting, packet filtering, and captcha functionality EndGame does.
* [NGINX Development Kit](https://github.com/vision5/ngx_devel_kit) - Development Kit for NGINX (dependency)

Libraries:
* [LUAJIT2 NGINX](https://github.com/openresty/luajit2) - Just in time compiler for LUA.
* [LUA Resty String](https://github.com/openresty/lua-resty-string) - String functions for ngx_lua and LUAJIT2
* [LUA Resty Cookie](https://github.com/cloudflare/lua-resty-cookie) - Provides cookie manipulation
* [LUA Resty Session](https://github.com/bungle/lua-resty-session) - Provides session manipulation
* [LUA Resty AES](https://github.com/c64bob/lua-resty-aes/raw/master/lib/resty/aes_functions.lua) - AES Functions file for LUA. Used for shared session cookies.
* [LUA Resty Random](https://github.com/bungle/lua-resty-random) - A *true* random number library for OpenResty.

### Configuration

EndGame requires configuration to work properly.

The main configuration can be found at the top of the `setup.sh` file. It customizes most of the script

There are options. Such as:
* MASTERONION - Your V3 Master OnionBalance Address **WITHOUT http://** (example: dreadytofatroptsdj6io7l3xptbet6onoyno2yv7jicoxknyazubrad.onion)
* TORAUTHPASSWORD - Password which is used for your Tor Control Port Authentication with NGINX. Alphanumeric without spaces (example: passwordIcanremembertyping)
* KEY - Alphanumeric Key for the shared front session key. Random alphanumberic 64 or 128 would do fine. (example: isthis64charactorsalreadyicantbelieveitwowsocoolwaitnotyetohdarn)
* SALT - 8 character salt used with the key. 8 random alphanumeric characters (example: saltsalt)
* SESSION_LENGTH - In seconds the amount of time until cookie timeout. Set it high as you can. (example: 3600 [aka 1 hour])
* HEXCOLOR - HEX color put into the css file to be not purple but your main site's color. Any CSS hex will work. (example: #9b59b6)
* SITENAME -  Site name automatically put in the captcha html file. (example: dread)
* LOCALPROXY - If true will set proxy_pass url to the PROXYPASSURL and disable load balanced Tor processes. If enabled will take the BACKENDONIONURL and configure load balanced socks_pass. It's highly recommended to proxy locally if possible.
* PROXYPASSURL - The local url used to proxy_pass all good connections. Not used if LOCALPROXY set to false.
* BACKENDONIONURL - The remote onion service endpoint. This onion is not public and should have no rate limiting or filtering on it. Generally the "core" server onion. Not used if LOCALPROXY set to true.

There is also some editing you need to do in the `caphtml_d.lua`, `naxsi_whitelist.rules`, `site.conf`, and `torrc` files.

- `resty/caphtml_d.lua` - Two Base64 Images. The favicon (line 143) and main logo (line 162). You can use [this](https://base64.guru/converter/encode/image/ico) for the favicon and [this](https://base64.guru/converter/encode/image) for the main logo.
- `queue.html` - Two base64 images. Search for <link href=" for the favicon and .logobgimg for the main logo. Update accordingly.
- `naxsi_whitelist.rules` - NAXSI's Whitelist Rules with some internal rules [see this](https://github.com/nbs-system/naxsi/wiki/internal-rules). To be configured for your specific application's use case.
- `site.conf` - Line 114 and 115 has the two rate limiting EndGame does. One by the circuit ID and one by the cookie. Depending on how your site calls files you may need to change these values.
    - Defaulty set to 6 consistent on line 114 and 115. 114 for circuit. 115 for cookie.
    - Line 263 has a nodelay burst of 10 for the circuit. Line 269 has a nodelay burst of 10 for the cookie.
    - Line 288-293 socks proxy_pass system. If you want EndGame to pass the filtered request over Tor you uncomment the socks_* lines and change the BACKENDONIONURL variable in the setup.sh file to your core webserver's private v3 address. If you do this you will need to comment the proxy_pass.
    - Line 273 regular proxy_pass. If you have a secure local connection you want to use the regular proxy_pass for reliability and latency improvements. Just change it to your core webserver's private IP. This is set as the default for performance reasons.
- `torrc` - Depending on what you set your burst as change the HiddenServiceMaxStreams value to that plus 2.

### Setup Process

EndGame is **HIGHLY** scripted. Which means it is important you run it on the system that it is intended for or there could be issues. Endgame is designed for `DEBIAN 10`.

##### STEP 1:

You need a v3 onionbalance master onion! There is a script included in the onionbalance folder. Onionbalance signed specific descriptors and publishes them to the Tor network. There is no site traffic that goes through onionbalance. As such you can put it on a low powered server or even on your core server. Recommendation is 2 CPU Cores with 2GB of RAM.

##### STEP 2:

After you get your onionbalance master onion you should configure the endgame script for your site with the correct variables. While EndGame is designed to work for most onion services it isn't perfect for everyone. You will need to customize it for your own needs.

##### STEP 3:

Transfer the files over to a blank debian 10 system with ideally 4 CPU cores and 4GB of RAM. High clocked cores are important (at least 3GHZ). Tor is single threaded with minimal hardware acceleration; getting higher performance cores will provide more resistance to attacks.

After the files are transferred make the setup.sh file executable and run it with bash. It will do the full setup process and export an onion URL. Visit that onion and hopefully everything will work. If not look at the error logs (located in /var/logs/nginx/) and see where you messed up.

##### STEP 4:

Scale out. Without scaling out you are bring a knife to a gun fight. At minimum you need 3 fronts. Onionbalance v3 does have distinct descriptors now. You can scale to the moon and back. Endgame does make it much harder to take you down but you need to scale to keep up. Otherwise your front's Tor will get overloaded and you will go down. It's a dick measuring contest between you and the attacker. By scaling out you are effectively adding more length to your dick.

##### STEP 5:

After scaling out with multiple fronts add all their onion addresses to onionbalance's configuration and run it. Now you can publish that onionbalance master address as an EndGame protected address. That is it. Repeat these steps as many times as needed to make as many Endgame protected addresses to outscale any DDOSER.

### End Notes

EndGame isn't perfect. It can't protect against introduction cell type attacks (the Tor project will need to add POW at the introduction points to fix that). But it does provide good protection and scaling which makes it much harder to take you down overall for whatever people throw at you.

This all is a major step forward for the darknet community. Never give in to the extorting DDOSERS. You are only paying to be attacked with more power in the future. Instead stand together and say "NO". As a united front we will reach heights never seen before.  탈