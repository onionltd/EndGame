#!/bin/bash

tor
tor -f /etc/tor/torrc2
tor -f /etc/tor/torrc3
service vanguards start
exit 0