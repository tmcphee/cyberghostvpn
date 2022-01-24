#!/bin/bash
	config_ini=/home/root/.cyberghost/config.ini
	if [ -f "$config_ini" ]; then
		#Launch and connect to CyberGhost VPN [Example]
		sudo cyberghostvpn --connect --torrent --country-code NL --wireguard
		
		#Add CyberGhost nameserver to resolv for DNS
		echo 'nameserver 38.132.106.139' > /etc/resolv.conf
	fi
	